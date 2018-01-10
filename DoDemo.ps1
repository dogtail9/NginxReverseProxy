param
(
    [switch]$DEMO
)

function Request-Input
{
    param
    (
        [string] $message
    )

    if($DEMO)
    {
        Clear-Host
        Write-Host $message -ForegroundColor "yellow" -BackgroundColor "black"
        $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 
    }
}

function Wait-Input
{
    if($DEMO)
    {
        Write-Host $message -ForegroundColor "yellow" -BackgroundColor "black"
        $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 
    }
}

function Create-ProjectFolder
{
    if($DEMO)
    {
        Write-Host "Create project folder" -ForegroundColor "yellow" -BackgroundColor "black"
    }

    New-Item -Path . -Name DEMO -ItemType Directory
    
    Set-Location .\DEMO
    code .
}

function Create-SiteFolder
{
    if($DEMO)
    {
        Write-Host "Create SiteFolder" -ForegroundColor "yellow" -BackgroundColor "black"
    }
   
    New-Item -Path . -Name site -ItemType Directory
}

function Create-SiteHtml
{
    $html = @"
<html>
    <head><title>My Site</title></head>
    <body>
        <h1>My Site</h1>
    </body>
</html>
"@

    Set-Location .\site
    New-Item -Path . -Name source -ItemType Directory
    Set-Location .\source
    $html | Out-File index.html -Encoding utf8
    Set-Location ..
    Set-Location ..
}

function Create-SiteDockerfile
{
    $dockerfile = @"
FROM nginx

COPY site/source/ /usr/share/nginx/html
"@

    Set-Location .\site
    $dockerfile | Out-File Dockerfile -Encoding utf8
    Set-Location ..
}

function Build-SiteImage
{
    docker build -t site -f .\site\Dockerfile .
    docker images
    Wait-Input
}

function Run-SiteContainer
{
    docker run -d --name site -p 8080:80 site
    docker ps
    Wait-Input
}

function Open-SiteContainerInBrowser
{
    Start-Process "http://localhost:8080"
}

function Create-SubSiteFolder
{
    Set-Location .\site
    Set-Location .\source

    New-Item -Path . -Name subsite -ItemType Directory
    
    Set-Location ..
    Set-Location ..
}

function Create-SubSiteHtml
{
    $html = @"
<html>
    <head><title>My Site</title></head>
    <body>
        <h1>Subsite</h1>
    </body>
</html>
"@

    Set-Location .\site
    Set-Location .\source
    Set-Location .\subsite
    
    $html | Out-File index.html -Encoding utf8

    Set-Location ..
    Set-Location ..
    Set-Location ..
}

function Edit-SiteHtml 
{
    $html = @"
<html>
    <head><title>My Site</title></head>
    <body>
        <h1>My Site</h1>
        <a href="./subsite/index.html">Subsite</a>
    </body>
</html>
"@

    Set-Location .\site
    Set-Location .\source

    $html | Out-File index.html -Encoding utf8
    
    Set-Location ..
    Set-Location ..
}

function Remove-SiteContainer
{
    docker rm site -f
    docker ps
    Wait-Input
}

function Remove-SiteImage
{
    docker rmi site -f
    docker images
    Wait-Input
}

function Create-ProxyFolder
{
    New-Item -Path . -Name proxy -ItemType Directory
    Set-Location .\proxy

    New-Item -Path . -Name conf -ItemType Directory
    Set-Location ..
}

function Create-ProxyConfigFile
{
    $conf = @"
worker_processes 1;

events {
    worker_connections 1024;
}

http {
    proxy_set_header Host `$host;
    proxy_pass_request_headers on;
  
    server {
        server_name _;
        listen 80 default_server;
    
        location / {
            proxy_pass http://site/;
        }
    }
}
"@
    Set-Location .\proxy
    Set-Location .\conf

    $conf | Out-File nginx.conf -Encoding ASCII

    Set-Location ..
    Set-Location ..
}

function Create-ProxyDockerfile
{
    $dockerfile = @"
FROM nginx

EXPOSE 80
    
COPY proxy/conf /etc/nginx
"@

    Set-Location .\proxy
    $dockerfile | Out-File Dockerfile -Encoding utf8
    Set-Location ..
}

function Build-ProxyImage
{
    docker build -t proxy -f .\proxy\Dockerfile .
    docker images
    Wait-Input
}

function Create-TestNetwork
{
    docker network create Test
    docker network ls
    Wait-Input
}

function Run-SiteContainerOnTestNetwork
{
    docker run -d -P --name site --network Test site
    docker ps
    Wait-Input
}

function Run-ProxyContainerOnTestNetwork
{
    docker run --name proxy -d -p 80:80 --network Test proxy
    docker ps
    Wait-Input
}

function Open-ProxyContainerInBrowser
{
    Start-Process "http://localhost"
    Wait-Input
}

function Create-NewSubSiteFolder
{
    New-Item -Path . -Name subsite -ItemType Directory
    Set-Location .\subsite

    New-Item -Path . -Name source -ItemType Directory
    Set-Location ..
}

function Create-NewSubSiteHtml
{
    $html = @"
<html>
    <head><title>My Site</title></head>
    <body>
        <h1>New Subsite</h1>
    </body>
</html>
"@
    Set-Location .\subsite
    Set-Location .\source

    $html | Out-File index.html -Encoding utf8

    Set-Location ..
    Set-Location ..
}

function Create-NewSubSiteDockerfile
{
    $dockerfile = @"
FROM nginx

COPY subsite/source/ /usr/share/nginx/html/subsite
"@
    
        Set-Location .\subsite
        $dockerfile | Out-File Dockerfile -Encoding utf8
        Set-Location ..
}

function Edit-ProxyConfigFile
{
    $conf = @"
worker_processes 1;

events {
    worker_connections 1024;
}

http {
    proxy_set_header Host `$host;
    proxy_pass_request_headers on;
  
    server {
        server_name _;
        listen 80 default_server;
    
        location / {
            proxy_pass http://site/;
        }

        location /subsite/ {
            proxy_pass http://subsite;
        }
    }
}
"@
    Set-Location .\proxy
    Set-Location .\conf

    $conf | Out-File nginx.conf -Encoding ASCII

    Set-Location ..
    Set-Location ..
}

function Remove-ProxyContainer
{
    docker rm proxy -f
    docker rmi proxy
    docker ps

    Wait-Input
}

function Build-NewSubSiteImage
{
    docker build -t subsite -f .\subsite\Dockerfile .
    docker ps
    Wait-Input
}

function Run-NewSubSiteContainerOnTestNetwork
{
    docker run -d -P --name subsite --network Test subsite
    docker ps
    Wait-Input
}

function Remove-AllContainersAndNetwork
{
    docker rm site subsite proxy -f
    docker ps
    docker network rm Test
    docker network ls
    Wait-Input
}

function Create-DockerComposeFile
{
    $dockerCompose = @"
version: '3.3'

services:

  site:
    image: site
    networks:
      - app-net
  
  subsite:
    image: subsite
    networks:
      - app-net

  proxy:
    image: proxy
    ports:
      - "80:80"
    depends_on:
      - site
      - subsite
    networks:
      - app-net
    
networks:
  app-net:    
"@

    $dockerCompose | Out-File docker-compose.yml -Encoding utf8
}

function Run-DockerComposeFile
{
    docker-compose -f .\docker-compose.yml up -d
    docker ps
    docker network ls
    Wait-Input
}

function Create-DockerComposeBuildFile
{
    $dockerComposeBuild = @"
version: '3.3'

services:

  site:
    build:
      context: ./
      dockerfile: ./site/Dockerfile
    
  subsite:
    build:
      context: ./
      dockerfile: ./subsite/Dockerfile
    
  proxy:
    build:
      context: ./
      dockerfile: ./proxy/Dockerfile
"@

    $dockerComposeBuild | Out-File docker-compose.build.yml -Encoding utf8
}

function Build-DockerComposeWithBuildFile
{
    docker-compose -f .\docker-compose.yml down
    docker rmi site subsite proxy -f

    docker-compose -f .\docker-compose.yml -f .\docker-compose.build.yml build
    docker images
    Wait-Input
}

function Run-DockerComposeWithBuildFile
{
    docker-compose -f .\docker-compose.yml -f .\docker-compose.build.yml up --build -d
    docker ps
    Wait-Input
}

function Remove-DockerCompose
{
    docker-compose -f .\docker-compose.yml down
    docker ps
    docker network ls
    docker images
    Wait-Input
}

Clear-Host

# Import MDEVGit
Request-Input -message "Press a key to Start the Demo"
docker rm (docker ps -a -q) -f
docker rmi site subsite proxy -f
Remove-Item DEMO -Recurse -ErrorAction Ignore

Request-Input -message "Create-SiteFolder"
Create-ProjectFolder
Create-SiteFolder

Request-Input -message "Create-SiteHtml"
Create-SiteHtml

Request-Input -message "Create-SiteDockerfile"
Create-SiteDockerfile

Request-Input -message "Build-SiteImage"
Build-SiteImage

Request-Input -message "Run-SiteContainer"
Run-SiteContainer

Request-Input -message "Open-SiteContainerInBrowser"
Open-SiteContainerInBrowser

Request-Input -message "Create-SubSiteFolder"
Create-SubSiteFolder

Request-Input -message "Create-SubSiteHtml"
Create-SubSiteHtml

Request-Input -message "Edit-SiteHtml"
Edit-SiteHtml

Request-Input -message "Remove-SiteContainer"
Remove-SiteContainer

Request-Input -message "Remove-SiteImage"
Remove-SiteImage

Request-Input -message "Build-SiteImage"
Build-SiteImage

Request-Input -message "Run-SiteContainer"
Run-SiteContainer

Request-Input -message "Open-SiteContainerInBrowser"
Open-SiteContainerInBrowser

Request-Input -message "Create-ProxyFolder"
Create-ProxyFolder

Request-Input -message "Create-ProxyConfigFile"
Create-ProxyConfigFile

Request-Input -message "Create-ProxyDockerfile"
Create-ProxyDockerfile

Request-Input -message "Remove-SiteContainer"
Remove-SiteContainer

Request-Input -message "Build-ProxyImage"
Build-ProxyImage

Request-Input -message "Create-TestNetwork"
Create-TestNetwork

Request-Input -message "Run-SiteContainerOnTestNetwork"
Run-SiteContainerOnTestNetwork

Request-Input -message "Run-ProxyContainerOnTestNetwork"
Run-ProxyContainerOnTestNetwork

Request-Input -message "Open-ProxyContainerInBrowser"
Open-ProxyContainerInBrowser

Request-Input -message "Create-NewSubSiteFolder"
Create-NewSubSiteFolder

Request-Input -message "Create-NewSubSiteHtml"
Create-NewSubSiteHtml

Request-Input -message "Create-NewSubSiteDockerfile"
Create-NewSubSiteDockerfile

Request-Input -message "Edit-ProxyConfigFile"
Edit-ProxyConfigFile

Request-Input -message "Remove-ProxyContainer"
Remove-ProxyContainer

Request-Input -message "Build-ProxyImage"
Build-ProxyImage

Request-Input -message "Build-NewSubSiteImage"
Build-NewSubSiteImage

Request-Input -message "Run-NewSubSiteContainerOnTestNetwork"
Run-NewSubSiteContainerOnTestNetwork

Request-Input -message "Run-ProxyContainerOnTestNetwork"
Run-ProxyContainerOnTestNetwork

Request-Input -message "Open-ProxyContainerInBrowser"
Open-ProxyContainerInBrowser

Request-Input -message "Remove-AllContainersAndNetwork"
Remove-AllContainersAndNetwork

Request-Input -message "Create-DockerComposeFile"
Create-DockerComposeFile

Request-Input -message "Run-DockerComposeFile"
Run-DockerComposeFile

Request-Input -message "Open-ProxyContainerInBrowser"
Open-ProxyContainerInBrowser

Request-Input -message "Create-DockerComposeBuildFile"
Create-DockerComposeBuildFile

Request-Input -message "Build-DockerComposeWithBuildFile"
Build-DockerComposeWithBuildFile

Request-Input -message "Run-DockerComposeWithBuildFile"
Run-DockerComposeWithBuildFile

Request-Input -message "Remove-DockerCompose"
Remove-DockerCompose

Set-Location ..
docker rmi site subsite proxy -f

if($DEMO)
{
    Clear-Host
}

Write-Host "THE END" -ForegroundColor "yellow" -BackgroundColor "black"