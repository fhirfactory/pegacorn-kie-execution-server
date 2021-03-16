FROM fhirfactory/pegacorn-base-docker-wildfly:1.0.0

#WAR file from https://repository.jboss.org/nexus/content/groups/public-jboss/org/kie/server/kie-server/7.50.0.Final//kie-server-7.50.0.Final.zip


COPY kie-server-users.properties $JBOSS_HOME/standalone/configuration/application-users.properties
COPY kie-server-roles.properties $JBOSS_HOME/standalone/configuration/application-roles.properties
COPY kie-server-7.50.0.Final.war $JBOSS_HOME/standalone/deployments/kie-server.war
COPY authentication.cli $JBOSS_HOME/bin/authentication.cli


#######################################################################################################################################################################################
# The base image enables SSL however the workbench fails when SSL is enabled so until that issue is investigated and fixed just override any changes the base image made to the       #
# standalone.xml file.  Also any commands in the .sh files related to SSL have been commented out.       																	          #
#                                    																																				  #
# This is temporary.																																							      #		
#######################################################################################################################################################################################
RUN mv $JBOSS_HOME/standalone/configuration/standalone.xml $JBOSS_HOME/standalone/configuration/standalone.xml.orig && \
    cp $JBOSS_HOME/standalone/configuration/standalone-full-ha.xml $JBOSS_HOME/standalone/configuration/standalone.xml
    
    

RUN $JBOSS_HOME/bin/jboss-cli.sh --file=$JBOSS_HOME/bin/authentication.cli && \
rm -rf $JBOSS_HOME/standalone/configuration/standalone_xml_history/current


COPY start-wildfly.sh /
COPY setup-env-then-start-wildfly-as-jboss.sh /

ARG IMAGE_BUILD_TIMESTAMP
ENV IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}
RUN echo IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}


USER root
# Install gosu based on
# 1. https://gist.github.com/rafaeltuelho/6b29827a9337f06160a9
# 2. https://github.com/tianon/gosu
# 3. https://github.com/tianon/gosu/releases/download/1.12/gosu-amd64
COPY gosu-amd64 /usr/local/bin/gosu
RUN chmod +x /usr/local/bin/gosu && \
	chmod +x /setup-env-then-start-wildfly-as-jboss.sh && \
   	chmod +x /start-wildfly.sh
   	
CMD ["/setup-env-then-start-wildfly-as-jboss.sh"]
