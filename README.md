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

You should noe see the namespace-configuration operator pod e.g.

```
NAME                                                READY   STATUS    RESTARTS   AGE
namespace-configuration-operator-6b7b6ff978-slqwr   1/1     Running   0          51s
```

### Configure Group Configs

`oc apply -f portfolio-app-admin.yml`

`oc apply -f portfolio-app-dev.yml`

`oc apply -f portfolio-app-view.yml`

# Group sync

## Known issues

* The group-sync operator active directory plugin uses "Azure AD Graph API" which is on a depreciation path since June 30th 2020.  There are plans to move to Microsoft Graph but there is not a concrete date for this at present
* Once changes are made to groups (e.g. label updates), the group will no longer be updated by the group-sync operator e.g. in the event new users are added.  An issue has been created for this and a PR is in the works.

## Setup

In order to connect to Azure AD and sync groups, we need to create Azure AD api access, to do this use the link below:

[Configure Azure AD api access](azure-setup.md)

Create a group-sync-operator namespace 

`oc new-project group-sync-operator`

Install group sync operator

`oc apply -f gc-operators.yml`

`oc apply -f gc-operator-subscriptions.yml`

You should see a pod e.g.

```
NAME                                   READY   STATUS              RESTARTS   AGE
group-sync-operator-54f99579f6-h96jb   0/1     ContainerCreating   0          1s
```

Create secret using the information retrieved from the Azure app api setup

`oc create secret generic azure-group-sync --from-literal=AZURE_SUBSCRIPTION_ID=xxxx --from-literal=AZURE_TENANT_ID=xxxx --from-literal=AZURE_CLIENT_ID=xxxx --from-literal=AZURE_CLIENT_SECRET=xxxx`

Deploy azure GroupSync object

`oc apply -f ./group-sync/azure.yml`

Check the logs of the group-sync-operator pod, you should see something like:

```
{"level":"info","ts":1600871907.470308,"logger":"controller_groupsync","msg":"Reconciling GroupSync","Request.Namespace":"","Request.Name":"azure-groupsync"}
{"level":"info","ts":1600871907.570612,"logger":"controller_groupsync","msg":"Beginning Sync","Request.Namespace":"","Request.Name":"azure-groupsync","Provider":"azure"}
{"level":"info","ts":1600871910.856552,"logger":"controller_groupsync","msg":"Sync Completed Successfully","Request.Namespace":"","Request.Name":"azure-groupsync","Provider":"azure","Groups Created or Updated":10}
```

When groups are created, run `./process-group.sh` to configure the labels for the namespace-operator to trigger namespace and role bindings.


