#!/usr/bin/env bash 
set -ex

echo "__installing argocd in ${BIN_DIR}___"
command -v  argocd && exit 0
 if [ -z $BIN_DIR ];then
    echo "____ Set env var BIN_DIR ___"
    exit 1
else
     echo ""installing archocd bin to ${BIN_DIR}
fi
cli_install () {
    which curl || (echo Please install curl & exit 1);
    echo ____ downloading ____
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 ${BIN_DIR}/argocd
    rm ./argocd-linux-amd64
    echo Installed argocd in ${BIN_DIR}
}
#todo add osx
if [ $(uname) == Darwin ]; then echo OSX not supported yet 
 echo unsupported
 brew install argcod
 # exit 0
else
   cli_install
fi
PATH=$PATH:$BIN_DIR which argocd 1>/dev/null || (echo cli install failed& exit 1)
