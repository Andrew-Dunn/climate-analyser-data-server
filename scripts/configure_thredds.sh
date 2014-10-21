#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )/.."

mv $DIR/tomcat/content/thredds/catalog.xml{,.old}
ln -s $DIR/thredds/catalog.xml $DIR/tomcat/content/thredds/catalog.xml
mv $DIR/tomcat/content/thredds/threddsConfig.xml{,.old}
ln -s $DIR/thredds/config.xml $DIR/tomcat/content/thredds/threddsConfig.xml
ln -s $DIR/datafiles $DIR/tomcat/content/thredds/public/files
ln -s $DIR/thredds/climate_analyser.pal $DIR/tomcat/webapps/thredds/WEB-INF/palettes/climate_analyser.pal
mv $DIR/tomcat/content/thredds/wmsConfig.xml{,.old}
ln -s $DIR/thredds/wmsConfig.xml $DIR/tomcat/content/thredds/wmsConfig.xml
