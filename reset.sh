oc delete -f portfolio-app-admin.yml
oc delete -f portfolio-app-dev.yml
oc delete -f portfolio-app-view.yml
oc delete -f ./portfolio1/app1/groups.yml
oc delete -f ./portfolio1/app2/groups.yml
oc delete -f ./portfolio2/app3/groups.yml
oc delete -f ./portfolio2/app4/groups.yml
oc delete -f ./portfolio1/groups.yml
oc delete -f ./portfolio2/groups.yml
oc delete -f ./portfolio1/users.yml
oc delete -f ./portfolio1/app1/users.yml
oc delete -f ./portfolio1/app2/users.yml
oc delete -f ./portfolio2/users.yml
oc delete -f ./portfolio2/app3/users.yml
oc delete -f ./portfolio2/app4/users.yml