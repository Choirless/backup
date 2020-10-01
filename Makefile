# Namespace functions will be created int
NAMESPACE_NAME ?= choirless

# Docker images
NODEJS_IMAGE ?= choirless/backup:latest

normalbuild: clean package build

build: package actions triggers rules list

fullclean: clean deletenamespace

fullbuild: namespace cos-auth build

deletenamespace:
	ic fn namespace delete $${namespace}

clean:
	ibmcloud fn property set --namespace $(NAMESPACE_NAME)
	$(eval NAMESPACE_ID := $(shell ibmcloud fn property get --namespace | cut -f 3))
	ic fn trigger list /$(NAMESPACE_ID) | grep "/$(NAMESPACE_ID)" | cut -d ' ' -f 1 | xargs -n1 ic fn trigger delete 
	ic fn action list /$(NAMESPACE_ID) | grep "/$(NAMESPACE_ID)" | cut -d ' ' -f 1 | xargs -n1 ic fn action delete
	ic fn rule list /$(NAMESPACE_ID) | grep "/$(NAMESPACE_ID)" | cut -d ' ' -f 1 | xargs -n1 ic fn rule delete
	ic fn package list /$(NAMESPACE_ID) | grep "/$(NAMESPACE_ID)" | cut -d ' ' -f 1 | xargs -n1 ic fn package delete

# Create and set namespace
namespace:
	ibmcloud fn namespace create $(NAMESPACE_NAME) --description "Choirless backup service"
	ibmcloud fn property set --namespace $(NAMESPACE_NAME)

# Create the package
package:
	ibmcloud fn property set --namespace $(NAMESPACE_NAME)
	ibmcloud fn package update choirless

# Actions
actions: backup_action

# Renderer front end
backup_action:
	ibmcloud fn action update $(NAMESPACE_NAME)/backup index.js \
	--docker $(NODEJS_IMAGE) --memory 2048 -t 600000 --param-file opts.json

triggers: data_backup_trigger \
		invitations_backup_trigger \
		keys_backup_trigger \
		render_status_backup_trigger \
		users_backup_trigger 

rules: data_backup_rule \
		invitations_backup_rule \
		keys_backup_rule \
		render_status_backup_rule \
		users_backup_rule 

# backup data every day
data_backup_trigger:
	ibmcloud fn trigger create data_backup_trigger \
		--feed /whisk.system/alarms/alarm \
		--param cron "5 0 * * *" \
		--param trigger_payload "{\"CLOUDANT_DB\":\"data\"}" 

# backup invitations every day
invitations_backup_trigger:
	ibmcloud fn trigger create invitations_backup_trigger --feed /whisk.system/alarms/alarm --param cron "10 0 * * *" --param trigger_payload "{\"CLOUDANT_DB\":\"invitations\"}" 

# backup keys every day
keys_backup_trigger:
	ibmcloud fn trigger create keys_backup_trigger --feed /whisk.system/alarms/alarm --param cron "15 0 * * *" --param trigger_payload "{\"CLOUDANT_DB\":\"keys\"}" 

# backup render_status every day
render_status_backup_trigger:
	ibmcloud fn trigger create render_status_backup_trigger --feed /whisk.system/alarms/alarm --param cron "20 0 * * *" --param trigger_payload "{\"CLOUDANT_DB\":\"render_status\"}" 

# backup users every day
users_backup_trigger:
	ibmcloud fn trigger create users_backup_trigger --feed /whisk.system/alarms/alarm --param cron "25 0 * * *" --param trigger_payload "{\"CLOUDANT_DB\":\"users\"}" 

# cron rule - data
data_backup_rule:
	ibmcloud fn rule update data_backup_rule data_backup_trigger choirless/backup

# cron rule - invitations
invitations_backup_rule:
	ibmcloud fn rule update invitations_backup_rule invitations_backup_trigger choirless/backup

# cron rule - keys
keys_backup_rule:
	ibmcloud fn rule update keys_backup_rule keys_backup_trigger choirless/backup

# cron rule - render_status
render_status_backup_rule:
	ibmcloud fn rule update render_status_backup_rule render_status_backup_trigger choirless/backup

# cron rule - users
users_backup_rule:
	ibmcloud fn rule update users_backup_rule users_backup_trigger choirless/backup

list:
	# Display entities in the current namespace
	ibmcloud fn list

