require 'spec_helper'

describe 'kafka::broker' do
  let(:title) { 'broker0' }
  let(:pre_condition) {[
      'include ::kafka::params',
      'include ::kafka',
  ]}

  context 'supported operating systems' do
    ['RedHat'].each do |osfamily|
      ['RedHat', 'CentOS', 'Amazon', 'Fedora'].each do |operatingsystem|
        let(:facts) {{
          :osfamily => osfamily,
          :operatingsystem => operatingsystem,
        }}

        default_broker_configuration_file  = '/opt/kafka/config/server-0.properties'
        default_logging_configuration_file = '/opt/kafka/config/log4j-0.properties'

        describe "kafka broker with default settings on #{osfamily}" do
          it { should contain_class("kafka::params") }
          it { should contain_class("kafka") }
          it { should contain_kafka__broker('broker0') }

          it { should contain_supervisor__service('kafka-broker-0').with({
            'ensure'      => 'present',
            'enable'      => true,
            'command'     => '/opt/kafka/bin/kafka-run-class.sh kafka.Kafka /opt/kafka/config/server-0.properties',
            'environment' => """JMX_PORT=9999,KAFKA_GC_LOG_OPTS=\"-Xloggc:/var/log/kafka/daemon-gc-0.log -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintGCTimeStamps\",KAFKA_HEAP_OPTS=\"-Xmx256M\",KAFKA_JMX_OPTS=\"-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false\",KAFKA_JVM_PERFORMANCE_OPTS=\"-server -XX:+UseCompressedOops -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -XX:+CMSClassUnloadingEnabled -XX:+CMSScavengeBeforeRemark -XX:+DisableExplicitGC -Djava.awt.headless=true\",KAFKA_LOG4J_OPTS=\"-Dlog4j.configuration=file:/opt/kafka/config/log4j-0.properties\",""",
            'user'        => 'kafka',
            'group'       => 'kafka',
            'autorestart' => true,
            'startsecs'   => 10,
            'retries'     => 999,
            'stopsignal'  => 'INT',
            'stopasgroup' => true,
            'stdout_logfile_maxsize' => '20MB',
            'stdout_logfile_keep'    => 5,
            'stderr_logfile_maxsize' => '20MB',
            'stderr_logfile_keep'    => 10,
          })}

          it { should contain_file(default_broker_configuration_file).
            with_content(/^broker.id=0$/).
            with_content(/^port=9092$/).
            with_content(/^log.dirs=\/app\/kafka-broker-0$/).
            with_content(/^zookeeper.connect=localhost:2181$/)
          }
          it { should contain_file(default_logging_configuration_file).
            with_content(/^log4j.appender.kafkaAppender.File=\/var\/log\/kafka\/server-0.log$/).
            with_content(/^log4j.appender.stateChangeAppender.File=\/var\/log\/kafka\/state-change-0.log$/).
            with_content(/^log4j.appender.requestAppender.File=\/var\/log\/kafka\/kafka-request-0.log$/).
            with_content(/^log4j.appender.controllerAppender.File=\/var\/log\/kafka\/controller-0.log$/)
          }
        end

        describe "kafka broker with a custom broker id on #{osfamily}" do
          let(:params) {{
            :broker_id => 23,
          }}

          it { should contain_file(default_broker_configuration_file).with_content(/^broker.id=23$/) }
        end

        describe "kafka broker with a custom port on #{osfamily}" do
          let(:params) {{
            :broker_port => 9093,
          }}

          it { should contain_file(default_broker_configuration_file).with_content(/^port=9093$/) }
        end

        describe "kafka broker with a single custom ZK server for $zookeeper_connect on #{osfamily}" do
          let(:params) {{
            :zookeeper_connect => ['zookeeper1:1234'],
          }}

          it { should contain_file(default_broker_configuration_file).
            with_content(/^zookeeper.connect=zookeeper1:1234$/)
          }
        end

        describe "kafka broker with a custom three-node ZK quorum for $zookeeper_connect on #{osfamily}" do
          let(:params) {{
            :zookeeper_connect => ['zookeeper1:1234', 'zookeeper2:5678','zkserver3:2181'],
          }}

          it { should contain_file(default_broker_configuration_file).
            with_content(/^zookeeper.connect=zookeeper1:1234,zookeeper2:5678,zkserver3:2181$/)
          }
        end

        describe "kafka broker with two directories for $log_dirs on #{osfamily}" do
          let(:params) {{
            :log_dirs => ['/app/kafka-broker-0', '/app/kafka-broker-1'],
          }}

          it { should contain_file(default_broker_configuration_file).
            with_content(/^log.dirs=\/app\/kafka-broker-0,\/app\/kafka-broker-1$/)
          }
        end

      end
    end
  end

end
