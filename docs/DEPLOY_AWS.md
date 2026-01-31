# Guía de Despliegue en AWS - YouScan ETL

## Arquitectura

```
EC2 (t3.small)
├── Docker
│   ├── PostgreSQL (puerto 5432 interno)
│   └── Metabase (puerto 3000 → público)
├── Python 3.11+
├── /home/ubuntu/youscan-etl/
│   ├── scripts ETL (desde GitHub)
│   └── data/ ← archivos semanales
└── Volumen EBS para persistencia
```

---

## Parte 0: Subir Proyecto a GitHub

### 0.1 Crear repositorio en GitHub

1. Ir a github.com → New repository
2. Nombre: `youscan-etl`
3. Privado (recomendado)
4. NO inicializar con README

### 0.2 Subir código desde local

```bash
cd /Users/robertoluna/Projects/youscan-etl

# Inicializar git
git init

# Crear .gitignore
cat > .gitignore << 'EOF'
.venv/
__pycache__/
*.pyc
.env
data/*.xlsx
data/*.csv
*.sql.bak
.DS_Store
EOF

# Agregar archivos
git add .
git commit -m "Initial commit: ETL YouScan + Metabase dashboards"

# Conectar con GitHub
git remote add origin git@github.com:TU_USUARIO/youscan-etl.git
git branch -M main
git push -u origin main
```

---

## Parte 1: Crear Instancia EC2

### 1.1 Lanzar instancia

1. Ir a AWS Console → EC2 → Launch Instance
2. Configurar:
   - **Nombre**: `youscan-dashboard`
   - **AMI**: Ubuntu 24.04 LTS
   - **Tipo**: `t3.small` (2 vCPU, 2GB RAM) - suficiente para inicio
   - **Key pair**: Crear o seleccionar una existente (guardar el .pem)
   - **Security Group**: Crear nuevo con reglas:

### 1.2 Configurar Security Group

| Tipo  | Puerto | Origen | Descripción |
|-------|--------|--------|-------------|
| SSH   | 22     | Tu IP  | Acceso admin |
| HTTP  | 80     | 0.0.0.0/0 | Redirect a HTTPS |
| HTTPS | 443    | 0.0.0.0/0 | Metabase público |
| Custom| 3000   | 0.0.0.0/0 | Metabase directo |

### 1.3 Almacenamiento

- **Root volume**: 20 GB gp3
- Marcar "Delete on termination": NO (para no perder datos)

### 1.4 Elastic IP (IP fija)

1. EC2 → Elastic IPs → Allocate
2. Asociar a tu instancia
3. Anotar la IP: `_______________`

---

## Parte 2: Configurar el Servidor

### 2.1 Conectar por SSH

```bash
# Dar permisos al archivo .pem
chmod 400 tu-llave.pem

# Conectar
ssh -i tu-llave.pem ubuntu@TU_IP_ELASTICA
```

### 2.2 Actualizar sistema e instalar dependencias

```bash
# Actualizar
sudo apt update && sudo apt upgrade -y

# Instalar Docker, Git y Python
sudo apt install -y docker.io docker-compose-v2 git python3 python3-pip python3-venv

# Agregar usuario al grupo docker
sudo usermod -aG docker ubuntu

# Cerrar sesión y reconectar para aplicar cambios
exit
```

Reconectar:
```bash
ssh -i tu-llave.pem ubuntu@TU_IP_ELASTICA
```

---

## Parte 3: Clonar Proyecto desde GitHub

### 3.1 Clonar repositorio

```bash
cd /home/ubuntu

# Si es repositorio privado, usar token o SSH key
git clone https://github.com/TU_USUARIO/youscan-etl.git

# O con SSH (si configuraste llaves)
# git clone git@github.com:TU_USUARIO/youscan-etl.git

cd youscan-etl
```

### 3.2 Configurar entorno Python

```bash
# Crear entorno virtual
python3 -m venv .venv
source .venv/bin/activate

# Instalar dependencias
pip install pandas psycopg2-binary python-dateutil openpyxl
```

### 3.3 Crear carpeta de datos

```bash
mkdir -p data
```

---

## Parte 4: Configurar Docker (PostgreSQL + Metabase)

### 4.1 Crear docker-compose de producción

```bash
cd /home/ubuntu/youscan-etl
nano docker-compose.prod.yml
```

Contenido:
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16
    container_name: youscan_postgres
    restart: always
    environment:
      POSTGRES_USER: youscan_admin
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: youscan
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "127.0.0.1:5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U youscan_admin -d youscan"]
      interval: 10s
      timeout: 5s
      retries: 5

  metabase:
    image: metabase/metabase:latest
    container_name: youscan_metabase
    restart: always
    environment:
      MB_DB_TYPE: postgres
      MB_DB_DBNAME: metabase
      MB_DB_PORT: 5432
      MB_DB_USER: youscan_admin
      MB_DB_PASS: ${POSTGRES_PASSWORD}
      MB_DB_HOST: postgres
      JAVA_TIMEZONE: America/Chihuahua
    ports:
      - "3000:3000"
    depends_on:
      postgres:
        condition: service_healthy

volumes:
  pgdata:
```

### 4.2 Crear archivo de variables de entorno

```bash
nano .env
```

Contenido (cambiar la contraseña):
```
POSTGRES_PASSWORD=TuContraseñaSegura123!
PGHOST=localhost
PGPORT=5432
PGDATABASE=youscan
PGUSER=youscan_admin
PGPASSWORD=TuContraseñaSegura123!
```

### 4.3 Iniciar servicios

```bash
# Cargar variables
source .env

# Iniciar contenedores
docker compose -f docker-compose.prod.yml up -d

# Verificar que estén corriendo
docker ps

# Ver logs si hay problemas
docker logs youscan_postgres
docker logs youscan_metabase
```

### 4.4 Crear base de datos para Metabase

```bash
# Conectar a PostgreSQL
docker exec -it youscan_postgres psql -U youscan_admin -d youscan

# Dentro de psql, crear BD para Metabase
CREATE DATABASE metabase;
\q
```

### 4.5 Reiniciar Metabase para que use la nueva BD

```bash
docker restart youscan_metabase
```

---

## Parte 5: Inicializar Base de Datos

### 5.1 Ejecutar scripts SQL

```bash
cd /home/ubuntu/youscan-etl
source .env

# Ejecutar schema inicial
docker exec -i youscan_postgres psql -U youscan_admin -d youscan < sql/001_init.sql

# Verificar tablas
docker exec -it youscan_postgres psql -U youscan_admin -d youscan -c "\dt"
```

Deberías ver:
```
 Schema |        Name         | Type  |
--------+---------------------+-------+
 public | ingestion_runs      | table |
 public | mention_occurrences | table |
 public | mention_tags        | table |
 public | mentions            | table |
 public | metrics             | table |
 public | qual_insights       | table |
 public | tags                | table |
```

---

## Parte 6: Cargar Datos Iniciales

### 6.1 Subir archivos de datos

Desde tu máquina local:
```bash
# Subir Excel de menciones
scp -i /ruta/a/tu-llave.pem \
  data/YouScan-*.xlsx \
  ubuntu@TU_IP_ELASTICA:/home/ubuntu/youscan-etl/data/

# Subir CSVs cualitativos
scp -i /ruta/a/tu-llave.pem \
  data/*-texto-cualitativo.csv \
  ubuntu@TU_IP_ELASTICA:/home/ubuntu/youscan-etl/data/
```

### 6.2 Ejecutar ETL de menciones

```bash
# En el servidor
cd /home/ubuntu/youscan-etl
source .venv/bin/activate
source .env

# Editar la ruta del archivo en etl_youscan.py si es necesario
nano etl_youscan.py
# Cambiar EXCEL_PATH al archivo correcto

# Ejecutar
python etl_youscan.py
```

### 6.3 Ejecutar ETL de texto cualitativo

```bash
python etl_texto_cualitativo.py data/1-marcobonilla-texto-cualitativo.csv
# Seguir los menús interactivos
```

---

## Parte 7: Configurar Metabase

### 7.1 Acceder a Metabase

1. Abrir navegador: `http://TU_IP_ELASTICA:3000`
2. Completar setup inicial:
   - Crear cuenta admin
   - Agregar conexión a PostgreSQL:
     - Host: `postgres` (nombre del contenedor)
     - Port: `5432`
     - Database: `youscan`
     - Username: `youscan_admin`
     - Password: (la que configuraste)

### 7.2 Importar dashboards

Si tienes dashboards exportados, importarlos desde:
Settings → Admin → Databases → Sync

### 7.3 Configurar timezone

Settings → Admin → Localization → Report Timezone → UTC

---

## Parte 8: Configurar Dominio y HTTPS (Opcional pero recomendado)

### 8.1 Instalar Nginx y Certbot

```bash
sudo apt install -y nginx certbot python3-certbot-nginx
```

### 8.2 Configurar Nginx

```bash
sudo nano /etc/nginx/sites-available/metabase
```

Contenido:
```nginx
server {
    listen 80;
    server_name tu-dominio.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# Activar sitio
sudo ln -s /etc/nginx/sites-available/metabase /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 8.3 Obtener certificado SSL

```bash
sudo certbot --nginx -d tu-dominio.com
```

---

## Parte 9: Flujo Semanal de Actualización

### 9.1 Checklist semanal

```
□ 1. Exportar de YouScan:
     - Excel de menciones de la semana
     - CSV cualitativo por cada actor

□ 2. Subir archivos al servidor:
     scp -i llave.pem data/*.xlsx ubuntu@IP:/home/ubuntu/youscan-etl/data/
     scp -i llave.pem data/*.csv ubuntu@IP:/home/ubuntu/youscan-etl/data/

□ 3. Conectar al servidor:
     ssh -i llave.pem ubuntu@IP

□ 4. Activar entorno y actualizar código:
     cd /home/ubuntu/youscan-etl
     git pull                        # ← actualizar si hay cambios
     source .venv/bin/activate
     source .env

□ 5. Ejecutar ETL menciones:
     # Editar EXCEL_PATH en etl_youscan.py con el nuevo archivo
     nano etl_youscan.py
     python etl_youscan.py

□ 6. Ejecutar ETL cualitativo (por cada actor):
     python etl_texto_cualitativo.py data/1-actor-texto-cualitativo.csv

□ 7. Verificar en Metabase que los datos aparezcan
```

### 9.2 Script de ayuda (ejecutar desde tu Mac)

Crear en tu máquina local `subir_datos.sh`:
```bash
#!/bin/bash

SERVER="ubuntu@TU_IP_ELASTICA"
KEY="/ruta/a/tu-llave.pem"
REMOTE_PATH="/home/ubuntu/youscan-etl/data/"

echo "=== Subiendo archivos a AWS ==="
scp -i $KEY data/*.xlsx $SERVER:$REMOTE_PATH 2>/dev/null
scp -i $KEY data/*-texto-cualitativo.csv $SERVER:$REMOTE_PATH 2>/dev/null

echo ""
echo "=== Archivos subidos. Conectando al servidor... ==="
echo ""
echo "Ejecuta estos comandos en el servidor:"
echo "  cd /home/ubuntu/youscan-etl"
echo "  source .venv/bin/activate && source .env"
echo "  python etl_youscan.py"
echo "  python etl_texto_cualitativo.py data/ARCHIVO.csv"
echo ""

ssh -i $KEY $SERVER
```

Dar permisos y usar:
```bash
chmod +x subir_datos.sh
./subir_datos.sh
```

### 9.3 Actualizar código si hiciste cambios locales

Si modificas queries o scripts localmente:
```bash
# En tu Mac
cd /Users/robertoluna/Projects/youscan-etl
git add .
git commit -m "Descripción del cambio"
git push

# En el servidor
ssh -i llave.pem ubuntu@IP
cd /home/ubuntu/youscan-etl
git pull
```

---

## Comandos Útiles

### Ver estado de contenedores
```bash
docker ps
docker logs youscan_postgres
docker logs youscan_metabase
```

### Reiniciar servicios
```bash
docker compose -f docker-compose.prod.yml restart
```

### Backup de base de datos
```bash
docker exec youscan_postgres pg_dump -U youscan_admin youscan > backup_$(date +%Y%m%d).sql
```

### Restaurar backup
```bash
docker exec -i youscan_postgres psql -U youscan_admin -d youscan < backup_20260116.sql
```

### Ver espacio en disco
```bash
df -h
docker system df
```

---

## Costos Estimados AWS

| Recurso | Especificación | Costo mensual aprox. |
|---------|----------------|---------------------|
| EC2 t3.small | 2 vCPU, 2GB RAM | ~$15-18 USD |
| EBS 20GB gp3 | Almacenamiento | ~$2 USD |
| Elastic IP | IP fija | $0 (si está asociada) |
| Data Transfer | Salida ~10GB | ~$1 USD |
| **Total** | | **~$18-21 USD/mes** |

---

## Troubleshooting

### Metabase no carga
```bash
docker logs youscan_metabase
# Verificar que PostgreSQL esté healthy
docker ps
```

### Error de conexión a PostgreSQL
```bash
# Verificar que el contenedor esté corriendo
docker ps | grep postgres

# Probar conexión
docker exec -it youscan_postgres psql -U youscan_admin -d youscan -c "SELECT 1"
```

### ETL falla con error de conexión
```bash
# Verificar variables de entorno
echo $PGHOST $PGPORT $PGUSER

# Probar conexión desde Python
python -c "import psycopg2; psycopg2.connect(host='localhost', port=5432, dbname='youscan', user='youscan_admin', password='TuPassword')"
```

### Disco lleno
```bash
# Limpiar imágenes Docker no usadas
docker system prune -a

# Ver archivos grandes
du -sh /home/ubuntu/youscan-etl/data/*
```
