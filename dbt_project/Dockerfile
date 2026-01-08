FROM python:3.10-slim

# 安装 ODBC 驱动依赖
RUN apt-get update && apt-get install -y \
    gnupg \
    unixodbc \
    unixodbc-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 安装 Microsoft SQL ODBC Driver 18
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/11/prod.list \
        > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql18

# 安装 dbt-core 和 dbt-sqlserver
RUN pip install --upgrade pip \
    && pip install dbt-core dbt-sqlserver

WORKDIR /usr/app