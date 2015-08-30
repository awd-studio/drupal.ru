#!/bin/sh
echo "INIT DEVEL Drupal.ru Version"

CORE='drupal-6'
SITEPATH="$HOME/domains/$SETTINGS_DOMAIN"
CONTRIB="acl bbcode bueditor cacherouter captcha  comment_notify comment_upload diff fasttoggle flag flag_abuse geshifilter google_plusone gravatar imageapi imagecache imagecache_profiles live_translation noindex_external_links pathauto pearwiki_filter privatemsg quote simplenews smtp spambot tagadelic taxonomy_manager token transliteration  views xmlsitemap "

echo "Full site path: $SITEPATH"
echo "Site core: $CORE"
echo "Deploy DIR: $GITLC_DEPLOY_DIR"

cd $SITEPATH
echo "Download DRUPAL."

drush dl $CORE --drupal-project-rename="drupal"

rsync -a $SITEPATH/drupal/ $SITEPATH
rm -rf tmp

echo "Install DRUPAL"

/usr/bin/drush site-install default -y --root=$SITEPATH --account-name=$SETTINGS_ACCOUNT_NAME --account-mail=$SETTINGS_ACCOUNT_MAIL --account-pass=$SETTINGS_ACCOUNT_PASS --uri=http://$SETTINGS_DOMAIN --site-name="$SETTINGS_SITE_NAME" --site-mail=$SETTINGS_SITE_MAIL --db-url=mysql://$SETTINGS_DATABASE_USER:$SETTINGS_DATABASE_PASS@localhost/$SETTINGS_DATABASE_NAME

echo "Install contrib modules"

mkdir -p $SITEPATH/sites/all/modules/contrib
drush dl $CONTRIB
drush -y en $CONTRIB

echo "Install captcha_pack"
drush dl captcha_pack
drush -y en ascii_art_captcha css_captcha

echo "Install other modules"
drush -y en imageapi_imagemagick flag_actions geshinode imagecache_ui pm_block_user pm_email_notify privatemsg_filter token_actions views_ui book forum geshinode php

echo "Install drupal.ru modules"
mkdir -p $SITEPATH/sites/all/modules/local

ln -s $GITLC_DEPLOY_DIR/modules/* $SITEPATH/sites/all/modules/local/

echo "Install drupal.ru themes"
mkdir -p $SITEPATH/sites/all/themes/local

ln -s $GITLC_DEPLOY_DIR/themes/* $SITEPATH/sites/all/themes/local/


# Find all info files
modules_enable="";
for file in $(find $GITLC_DEPLOY_DIR -name \*.info -print)
do
  filename=$(basename "$file")
  modules_enable+="${filename%.*},"
done

echo "Enable modules and themes: $modules_enable"
drush -y en $modules_enable

echo "Set novosibirsk theme as default"
drush vset theme_default novosibirsk
echo "Set garland theme as admin theme"
drush vset admin_theme garland

if [ -n "SETTINGS_DEVEL" ]; then
  drush dl devel
  drush en devel -y
  drush en devel_generate -y
  drush generate-content 200
  drush generate-users 100
fi  

echo "Migrating Menu structure"

mkdir -p $SITEPATH/sites/all/modules/github
cd  $SITEPATH/sites/all/modules/github

git clone https://github.com/itpatrol/drupal_deploy.git
cd drupal_deploy
git checkout 6.x

cd  $SITEPATH
drush -y en drupal_deploy

echo "Import roles"
drush ddi roles --file=$GITLC_DEPLOY_DIR/data/roles.export

echo "Import filters"
drush ddi filters --file=$GITLC_DEPLOY_DIR/data/filters.export

echo "Import menu structure"
drush ddi menu --file=$GITLC_DEPLOY_DIR/data/menu_links.export

echo "Import blocks"
drush ddi blocks --file=$GITLC_DEPLOY_DIR/data/novosibirsk.blocks.export

echo "Import nodetypes"
drush ddi node_types --file=$GITLC_DEPLOY_DIR/data/node_types.export



echo "Please check http://$SETTINGS_DOMAIN"
