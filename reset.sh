oc delete -f portfolio-app-admin.yml
oc delete -f portfolio-app-dev.yml
oc delete -f portfolio-app-view.yml
oc delete -f ./groups/app1-admin.yml
oc delete -f ./groups/app1-dev.yml
oc delete -f ./groups/app1-view.yml

oc delete project  portfolio1-app1-dev
oc delete project  portfolio1-app1-qa
oc delete project  portfolio1-app1-uat