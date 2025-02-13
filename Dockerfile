ARG IMAGE=intersystems/iris:2019.1.0S.111.0
ARG IMAGE=store/intersystems/iris:2019.1.0.511.0-community
FROM $IMAGE

WORKDIR /opt/app

COPY ./Installer.cls ./
COPY ./cls/ ./src/

# download ZPM
RUN mkdir -p /tmp/deps \

 && cd /tmp/deps \

 && wget -q https://pm.community.intersystems.com/packages/zpm/latest/installer -O zpm.xml 


RUN iris start $ISC_PACKAGE_INSTANCENAME quietly EmergencyId=sys,sys && \
    /bin/echo -e "sys\nsys\n" \
            " Do ##class(Security.Users).UnExpireUserPasswords(\"*\")\n" \
            " Do ##class(Security.Users).AddRoles(\"admin\", \"%ALL\")\n" \
            " do ##class(Security.System).Get(,.p)\n" \
            " set p(\"AutheEnabled\")=\$zb(p(\"AutheEnabled\"),16,7)\n" \
            " do ##class(Security.System).Modify(,.p)\n" \
            " Do \$system.OBJ.Load(\"/tmp/deps/zpm.xml\", \"ck\")" \
            " Do \$system.OBJ.Load(\"/opt/app/Installer.cls\",\"ck\")\n" \
            " Set sc = ##class(App.Installer).setup(, 3)\n" \
            " If 'sc do \$zu(4, \$JOB, 1)\n" \
            " halt" \
    | iris session $ISC_PACKAGE_INSTANCENAME && \
    /bin/echo -e "sys\nsys\n" \
    | iris stop $ISC_PACKAGE_INSTANCENAME quietly

CMD [ "-l", "/usr/irissys/mgr/messages.log" ]