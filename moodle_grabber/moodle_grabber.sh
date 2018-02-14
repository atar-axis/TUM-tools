read -p "Login (e.g. go42) " USER
read -p "Password (e.g. xD): " PASS


FILE=links.txt
WGET_OPTIONS_LOGIN="--quiet"
WGET_OPTIONS_DL="--quiet --show-progress"


mkdir -p tmp
rm -rf tmp/*

mkdir -p dl


echo "* logging in..."
# We start at moodle - here we get providerId and the URL to shibboleth

wget $WGET_OPTIONS_LOGIN \
--save-cookies=./tmp/cookies1.txt \
--keep-session-cookies \
--output-document=./tmp/moodle_start.txt \
'https://www.moodle.tum.de'

url_shibbo=$(cat ./tmp/moodle_start.txt | grep /Login?providerId=https%3A%2F%2Ftumidp.lrz.de | sed -E 's/.*href="([^"]*).*/\1/')


# Now we can visit the shibboleth login page

wget $WGET_OPTIONS_LOGIN \
--load-cookies=./tmp/cookies1.txt \
--save-cookies=./tmp/cookies2.txt \
--keep-session-cookies \
--header="Referer: https://www.moodle.tum.de" \
--output-document=./tmp/login_sibbo.txt \
"$url_shibbo"

url_action=$(cat ./tmp/login_sibbo.txt | grep action= | sed -E 's/.*action="([^"]*).*/\1/')


# We log in using our username and password

wget $WGET_OPTIONS_LOGIN \
--load-cookies=./tmp/cookies2.txt \
--save-cookies=./tmp/cookies3.txt \
--keep-session-cookies \
--header="Referer: https://tumidp.lrz.de/idp/profile/SAML2/Redirect/SSO?execution=e1s1" \
--post-data="j_username=$USER&j_password=$PASS&donotcache=1&_eventId_proceed=" \
--output-document=./tmp/logged_in_ref.txt \
"https://tumidp.lrz.de/idp/profile/SAML2/Redirect/SSO?execution=e1s1"

# we have to preprocess the POST-strings a bit, otherwise SSO complains that it cannot decode the base64 strings
RelayState=$(cat ./tmp/logged_in_ref.txt | grep RelayState | sed -E 's/.*value="([^"]*).*/\1/' | sed -E 's/&#x3a;/%3A/')
SAMLResponse=$(cat ./tmp/logged_in_ref.txt | grep SAMLResponse | sed -E 's/.*value="([^"]*).*/\1/' | sed -E 's/=/%3D/g' | sed -E 's/\+/%2B/g')


# We are on a "press continue site now", we need to post some data (SAML)

wget $WGET_OPTIONS_LOGIN \
--load-cookies=./tmp/cookies3.txt \
--save-cookies=./tmp/cookies4.txt \
--keep-session-cookies \
--header="Referer: https://tumidp.lrz.de/idp/profile/SAML2/Redirect/SSO?execution=e1s1" \
--post-data="RelayState=$RelayState&SAMLResponse=$SAMLResponse" \
--output-document=./tmp/logged_in_rly.txt \
'https://www.moodle.tum.de/Shibboleth.sso/SAML2/POST'


# We are successfully logged in, we pick up a new moddle-session therefore
wget $WGET_OPTIONS_LOGIN \
--load-cookies=./tmp/cookies4.txt \
--save-cookies=./tmp/cookies5.txt \
--keep-session-cookies \
--output-document=./tmp/moodle_shibbo_auth.txt \
--header="Referer: https://tumidp.lrz.de/idp/profile/SAML2/Redirect/SSO" \
'https://www.moodle.tum.de/auth/shibboleth/index.php'


# Now we can do whatever we want
wget $WGET_OPTIONS_LOGIN \
--load-cookies=./tmp/cookies5.txt \
--save-cookies=./tmp/cookies6.txt \
--keep-session-cookies \
--output-document=./tmp/my_check.txt \
--header="Referer: Referer: https://tumidp.lrz.de/idp/profile/SAML2/Redirect/SSO?execution=e1s1" \
'https://www.moodle.tum.de/my/'


if grep -q "Meine Startseite" "./tmp/my_check.txt"; then
    echo "* successfully logged in"
  
    echo "* downloading files"
    # Now we can do whatever we want
    wget $WGET_OPTIONS_DL \
    --load-cookies=./tmp/cookies6.txt \
    --save-cookies=./tmp/cookies6.txt \
    --keep-session-cookies \
    --header="Referer: Referer: https://tumidp.lrz.de/idp/profile/SAML2/Redirect/SSO?execution=e1s1" \
    --directory-prefix=dl \
    --continue \
    -i $FILE
fi



rm -r tmp
