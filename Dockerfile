FROM openjdk:8-jdk-slim-stretch
LABEL author="Sasa Zejnilovic"
LABEL based_on="https://hub.docker.com/r/sequenceiq/hadoop-docker/"

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      curl \
      openssh-client \
      openssh-server \
    && rm -rf /var/lib/apt/lists/* \
    && curl -s https://archive.apache.org/dist/hadoop/core/hadoop-2.7.5/hadoop-2.7.5.tar.gz | tar -xz -C /usr/local/ \
    && ln -s /usr/local/hadoop-2.7.5 /usr/local/hadoop

# # passwordless ssh
RUN ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa \
    && cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

ENV HADOOP_PREFIX /usr/local/hadoop
ENV HADOOP_COMMON_HOME /usr/local/hadoop
ENV HADOOP_HDFS_HOME /usr/local/hadoop
ENV HADOOP_MAPRED_HOME /usr/local/hadoop
ENV HADOOP_YARN_HOME /usr/local/hadoop
ENV HADOOP_CONF_DIR /usr/local/hadoop/etc/hadoop
ENV YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop
ENV PATH $PATH:$JAVA_HOME/bin

RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/docker-java-home/\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh \
    && sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh \
    && mkdir $HADOOP_PREFIX/input \
    && cp $HADOOP_PREFIX/etc/hadoop/*.xml $HADOOP_PREFIX/input

# pseudo distributed
ADD core-site.xml.template $HADOOP_PREFIX/etc/hadoop/core-site.xml.template
ADD hdfs-site.xml $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml
ADD mapred-site.xml $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
ADD yarn-site.xml $HADOOP_PREFIX/etc/hadoop/yarn-site.xml
ADD ssh_config /root/.ssh/config
ADD bootstrap.sh /etc/bootstrap.sh

ENV BOOTSTRAP /etc/bootstrap.sh

RUN sed s/HOSTNAME/localhost/ /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml \
    && $HADOOP_PREFIX/bin/hdfs namenode -format \
    && chmod 600 /root/.ssh/config \
    && chown root:root /root/.ssh/config \
    && chmod +x /etc/bootstrap.sh \
    && chmod +x $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

# fix the 254 error code
RUN sed  -i "/^[^#]*UsePAM/ s/.*/#&/"  /etc/ssh/sshd_config \
    && echo "UsePAM no" >> /etc/ssh/sshd_config \
    && echo "Port 2122" >> /etc/ssh/sshd_config

RUN /etc/init.d/ssh start \
    && $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh \
    && $HADOOP_PREFIX/sbin/start-dfs.sh \
    && $HADOOP_PREFIX/bin/hdfs dfs -mkdir -p /user/root \
    && $HADOOP_PREFIX/bin/hdfs dfs -put $HADOOP_PREFIX/etc/hadoop/ input

CMD ["/etc/bootstrap.sh", "-d"]

# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090 8020 9000
# Mapred ports
EXPOSE 10020 19888
#Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088
#Other ports
EXPOSE 49707 2122
