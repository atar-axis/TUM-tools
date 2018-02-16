#!/bin/bash

# SETTINGS

DL_DIR=dl
TMP_DIR=tmp
FILE=links.txt

WGET_OPTIONS_LOGIN="--quiet"
WGET_OPTIONS_DL="--quiet --show-progress"


# CODE

## CREDENTIALS

echo -n "Login (e.g. go42haf): "
read USER

echo -n "Password: "
read -s PASS

echo -e "\n---"

## FOLDERS

mkdir -p $TMP_DIR
rm -rf $TMP_DIR/*
mkdir -p $DL_DIR

## LOGIN

echo -n "* logging in... "
### We start at moodle - here we get providerId and the URL to shibboleth

wget $WGET_OPTIONS_LOGIN \
--save-cookies=./$TMP_DIR/cookie.txt \
--keep-session-cookies \
--output-document=./$TMP_DIR/moodle_start.txt \
'https://www.moodle.tum.de'

url_shibbo=$(cat ./$TMP_DIR/moodle_start.txt | grep /Login?providerId=https%3A%2F%2Ftumidp.lrz.de | sed -E 's/.*href="([^"]*).*/\1/')


### Now we can visit the shibboleth login page

wget $WGET_OPTIONS_LOGIN \
--load-cookies=./$TMP_DIR/cookie.txt \
--save-cookies=./$TMP_DIR/cookie.txt \
--keep-session-cookies \
--header="Referer: https://www.moodle.tum.de" \
--output-document=./$TMP_DIR/login_sibbo.txt \
"$url_shibbo"

url_action=$(cat ./$TMP_DIR/login_sibbo.txt | grep action= | sed -E 's/.*action="([^"]*).*/\1/')


### We log in using our username and password

wget $WGET_OPTIONS_LOGIN \
--load-cookies=./$TMP_DIR/cookie.txt \
--save-cookies=./$TMP_DIR/cookie.txt \
--keep-session-cookies \
--header="Referer: https://tumidp.lrz.de/idp/profile/SAML2/Redirect/SSO?execution=e1s1" \
--post-data="j_username=$USER&j_password=$PASS&donotcache=1&_eventId_proceed=" \
--output-document=./$TMP_DIR/logged_in_ref.txt \
"https://tumidp.lrz.de/idp/profile/SAML2/Redirect/SSO?execution=e1s1"

### we have to preprocess the POST-strings a bit, otherwise SSO complains that it cannot decode the base64 strings
RelayState=$(cat ./$TMP_DIR/logged_in_ref.txt | grep RelayState | sed -E 's/.*value="([^"]*).*/\1/' | sed -E 's/&#x3a;/%3A/')
SAMLResponse=$(cat ./$TMP_DIR/logged_in_ref.txt | grep SAMLResponse | sed -E 's/.*value="([^"]*).*/\1/' | sed -E 's/=/%3D/g' | sed -E 's/\+/%2B/g')


### We are on a "press continue site now", we need to post some data (SAML)

wget $WGET_OPTIONS_LOGIN \
--load-cookies=./$TMP_DIR/cookie.txt \
--save-cookies=./$TMP_DIR/cookie.txt \
--keep-session-cookies \
--header="Referer: https://tumidp.lrz.de/idp/profile/SAML2/Redirect/SSO?execution=e1s1" \
--post-data="RelayState=$RelayState&SAMLResponse=$SAMLResponse" \
--output-document=./$TMP_DIR/logged_in_rly.txt \
'https://www.moodle.tum.de/Shibboleth.sso/SAML2/POST'


### We are successfully logged in, we pick up a new moddle-session therefore
wget $WGET_OPTIONS_LOGIN \
--load-cookies=./$TMP_DIR/cookie.txt \
--save-cookies=./$TMP_DIR/cookie.txt \
--keep-session-cookies \
--output-document=./$TMP_DIR/moodle_shibbo_auth.txt \
--header="Referer: https://tumidp.lrz.de/idp/profile/SAML2/Redirect/SSO" \
'https://www.moodle.tum.de/auth/shibboleth/index.php'


### Download my-page for testing purposes
wget $WGET_OPTIONS_LOGIN \
--load-cookies=./$TMP_DIR/cookie.txt \
--save-cookies=./$TMP_DIR/cookie.txt \
--keep-session-cookies \
--output-document=./$TMP_DIR/my_check.txt \
--header="Referer: Referer: https://tumidp.lrz.de/idp/profile/SAML2/Redirect/SSO?execution=e1s1" \
'https://www.moodle.tum.de/my/'


### Download files from linklist

if grep -q "Meine Startseite" "./$TMP_DIR/my_check.txt"; then
    echo "* ok"
  
    echo "* downloading files... "
    # Now we can do whatever we want
    wget $WGET_OPTIONS_DL \
    --load-cookies=./$TMP_DIR/cookie.txt \
    --save-cookies=./$TMP_DIR/cookie.txt \
    --keep-session-cookies \
    --header="Referer: Referer: https://tumidp.lrz.de/idp/profile/SAML2/Redirect/SSO?execution=e1s1" \
    --directory-prefix=$DL_DIR \
    --continue \
    -i $FILE
    
    #TODO: wget Ausgabe einrücken mit?:  | sed 's/^/  /g'
    
    echo "done"
    
else
    echo "failed"
fi



rm -r $TMP_DIR
