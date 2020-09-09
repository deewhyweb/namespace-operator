## OpenShift Namespace Operator Investigation

To run, install the OpenShift Namespace operator

### Create users

`oc apply -f ./users/app1-users.yml`

`oc apply -f ./users/portfolio1-users.yml`

## Create portfolio groups

`oc apply -f ./groups/portfolio1-groups.yml`

## Create Group Configs

`oc apply -f portfolio-app-admin.yml`

`oc apply -f portfolio-app-dev.yml`

`oc apply -f portfolio-app-view.yml`

## Create app1 admin group and trigger namespace creation

`oc apply -f ./groups/app1-admin.yml`

## Create dev and view app1 groups and role bindings

`oc apply -f ./groups/app1-dev.yml`

`oc apply -f ./groups/app1-view.yml`
