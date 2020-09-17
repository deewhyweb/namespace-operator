## OpenShift Namespace Operator

The challenge we're addressing in this POC is how to manage a hierarchy of users within an organization with the appropriate permissions on OpenShift projects.

The hierarchy we're implementing will be:

portfolio -> apps

For example portfolio1 is parent to app1 and app2, portfolio2 is parent to app3 and app4.

Users in groups at the porfiolio level will require permissions on all apps within that portfolio.

Users in groups at the app level will require permissions solely on that app. 

This POC will use GroupConfig objects from the OpenShift Namespace Operator to automate the creation of projects and role bindings based on group creation.

Groups need to be configured with labels in order to match the GroupConfig labelSelector.

For example, the portfolio-group-config GroupConfig object specifies the following labelSelector

```
apiVersion: redhatcop.redhat.io/v1alpha1
kind: GroupConfig
metadata:
  name: portfolio-group-config
spec:
  labelSelector:
    matchLabels:
      role: admin
```

The GroupConfig object will also use two additional labels to indicate portfolio name (portfolio) and application name (application).

To match this labelSelector, the group should have the following labels:

```
kind: Group
apiVersion: user.openshift.io/v1
metadata:
  name: app1-admin
  labels:
    portfolio: portfolio1
    application: app1
    role: admin

```

Once the GroupConfig object is in place.  When a group is created with the above labels, the following takes place:

* Namespace created:  portfolio1-app1-dev
* Namespace created:  portfolio1-app1-qa
* Namespace created:  portfolio1-app1-uat
* RoleBinding created: admin role -> portfolio1-admin group -> portfolio1-app1-dev namespace
* RoleBinding created: admin role -> app1-admin group -> portfolio1-app1-dev namespace
* RoleBinding created: edit role -> portfolio1-dev group -> portfolio1-app1-dev namespace
* RoleBinding created: view role -> portfolio1-qa group -> portfolio1-app1-dev namespace
* RoleBinding created: admin role -> portfolio1-admin group -> portfolio1-app1-qa namespace
* RoleBinding created: admin role -> app1-admin group -> portfolio1-app1-qa namespace
* RoleBinding created: view role -> portfolio1-dev group -> portfolio1-app1-qa namespace
* RoleBinding created: view role -> portfolio1-qa group -> portfolio1-app1-qa namespace
* RoleBinding created: admin role -> portfolio1-admin group -> portfolio1-app1-uat namespace
* RoleBinding created: admin role -> app1-admin group -> portfolio1-app1-uat namespace
* RoleBinding created: view role -> portfolio1-dev group -> portfolio1-app1-uat namespace
* RoleBinding created: view role -> portfolio1-qa group -> portfolio1-app1-uat namespace

Two additional GroupConfig objects are provided:

* portfolio-app-dev
* portfolio-app-view

To match the selectors for these GroupConfigs, the groups should have role = dev or view e.g.

```
kind: Group
apiVersion: user.openshift.io/v1
metadata:
  name: app1-dev
  labels:
    portfolio: portfolio1
    application: app1
    role: dev
users:
  - app1-dev
```

Once this group is created the following takes place:

* RoleBinding created: edit role -> app1-dev group -> portfolio1-app1-dev namespace
* RoleBinding created: view role -> app1-dev group -> portfolio1-app1-qa namespace
* RoleBinding created: view role -> app1-dev group -> portfolio1-app1-uat namespace

# Demo

To run, install the OpenShift Namespace operator

`oc new-project namespace-configuration-operator`

`oc apply -f operators.yml`

`oc apply -f operator-subscriptions.yml`

### Configure Group Configs

`oc apply -f portfolio-app-admin.yml`

`oc apply -f portfolio-app-dev.yml`

`oc apply -f portfolio-app-view.yml`

### Create users

Users would normally be created via integration with an external authentication provider, for this demo though we're going to create some sample users.


Portfolio1: 

* portfolio1-admin
* portfolio1-dev
* portfolio1-view

App level users

* app1-admin
* app1-dev
* app1-view

* app2-admin
* app2-dev
* app2-view

Portfolio2:

* portfolio2-admin
* portfolio2-dev
* portfolio2-view

App level users

* app3-admin
* app3-dev
* app3-view

* app4-admin
* app4-dev
* app4-view


`oc apply -f ./portfolio1/users.yml`

`oc apply -f ./portfolio1/app1/users.yml`

`oc apply -f ./portfolio1/app2/users.yml`

`oc apply -f ./portfolio2/users.yml`

`oc apply -f ./portfolio2/app3/users.yml`

`oc apply -f ./portfolio2/app4/users.yml`

## Create portfolio groups

We'll create three portfolio level groups for each portfolio:

* admin
* dev
* view

`oc apply -f ./portfolio1/groups.yml`

`oc apply -f ./portfolio2/groups.yml`

## Create app groups and trigger namespace creation

`oc apply -f ./portfolio1/app1/groups.yml`

`oc apply -f ./portfolio1/app2/groups.yml`

`oc apply -f ./portfolio2/app3/groups.yml`

`oc apply -f ./portfolio2/app4/groups.yml`

## Verifiying

Once all these objects are created running `oc get projects` should result in:

```
...
portfolio1-app1-dev                                                    Active
portfolio1-app1-qa                                                     Active
portfolio1-app1-uat                                                    Active
portfolio1-app2-dev                                                    Active
portfolio1-app2-qa                                                     Active
portfolio1-app2-uat                                                    Active
portfolio2-app3-dev                                                    Active
portfolio2-app3-qa                                                     Active
portfolio2-app3-uat                                                    Active
portfolio2-app4-dev                                                    Active
portfolio2-app4-qa                                                     Active
portfolio2-app4-uat                                                    Active
...
```

As you can see, 12 projects have been created, 3 for each app.  Each portfolio is related to two apps.

If we use one of these projects e.g. `oc project portfolio1-app1-dev`, then run `oc get rolebindings` we should see:

```
edit-app1-app1-dev-dev      3h49m
portfolio1-admin-app1-dev   3h49m
portfolio1-edit-app1-dev    3h49m
portfolio1-view-app1-dev    3h49m
system:deployers            3h49m
system:image-builders       3h49m
system:image-pullers        3h49m
view-app1-app1-view-dev     3h49m
```

We can now look at these role bindings e.g. `oc describe rolebinding portfolio1-admin-app1-dev` shows the ClusterRole "admin" is bound to two groups, "portfolio1-admin" and "app1-admin" which is correct.

```
Name:         portfolio1-admin-app1-dev
Labels:       <none>
Annotations:  <none>
Role:
  Kind:  ClusterRole
  Name:  admin
Subjects:
  Kind   Name              Namespace
  ----   ----              ---------
  Group  portfolio1-admin  
  Group  app1-admin        
```
# Group sync

Install group sync operator

Create secret

`oc create secret generic azure-group-sync --from-literal=AZURE_SUBSCRIPTION_ID=xxxx --from-literal=AZURE_TENANT_ID=xxxx --from-literal=AZURE_CLIENT_ID=xxxx --from-literal=AZURE_CLIENT_SECRET=xxxx`

Deploy azure GroupSync object

`oc apply -f ./group-sync/azure.yml`

When groups are created, run `./process-group.sh`


