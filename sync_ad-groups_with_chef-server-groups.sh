#!/usr/bin/bash

add_users_to_chefserver() {
  USERS=''
  AD_GROUP=$1
  CHEF_GROUP=$2

  local IFS=$'\n'
  cd $HOME/chef-repo/
  global_users=$(chef-server-ctl user-list)

  my_org_associated_users=$(knife show /groups/users.json | grep -v ".json" | python -c 'import json,sys; j=json.load(sys.stdin); print(j["users"]);' | sed -e 's/\[//g' -e 's/\]//g' -e "s/u'//g" -e "s/'//g" -e 's/,/\n/g' -e 's/ //g')
  usags=$(knife show /groups/users.json | grep -v ".json" | python -c 'import json,sys; j=json.load(sys.stdin); print(j["groups"]);' | sed -e 's/\[//g' -e 's/\]//g' -e "s/u'//g" -e "s/'//g" -e 's/,/\n/g' -e 's/ //g')
  for g in $usags; do
    users=$(knife show /groups/${g}.json | grep -v ".json" | python -c 'import json,sys; j=json.load(sys.stdin); print(j["users"]);' | sed -e 's/\[//g' -e 's/\]//g' -e "s/u'//g" -e "s/'//g" -e 's/,/\n/g' -e 's/ //g')
    if [ -z "$my_org_associated_users" ]; then
      my_org_associated_users="$users"
    else
      my_org_associated_users="${my_org_associated_users}\n${users}"
    fi
  done

  for u in `$HOME/get_ad_users.py $AD_GROUP" | awk '{print tolower($0)}'`; do
    if [ -n "$(echo $global_users | grep -P "^${u}$")" ]; then
      if [ -z "$(echo $my_org_associated_users" | grep -P "^${u}$")" ]; then
        chef-server-ctl org-user-add my_org "$u"
      fi
      if [ -z "$USERS" ]; then
        USERS="\"$u\""
      else
        USERS="${USERS}, \"$u\""
      fi
    fi
  done

  cat << EOF > groups/${CHEF_GROUP}.json
{
}
EOF
  knife upload groups
}

add_users_to_chefserver 'CN=AD_Group_ChefServer_NodeAdmins'
