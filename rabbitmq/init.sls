{%- from 'rabbitmq/map.jinja' import rabbitmq %}

{%- if 'key_url' in rabbitmq.repo and
       'key_file' in rabbitmq.repo and
       'refresh' in rabbitmq.repo %}

# These states for handling the GPG key are specific to YUM/RedHat.
# The APT on Debian derivatives doesn't need any special care.

rabbitmq/Install GPG key file:
  file.managed:
    - name: {{ rabbitmq.repo.key_file }}
    - source: {{ rabbitmq.repo.key_url }}
    - skip_verify: True
    - user: root
    - group: root
    - mode: 0644

  {%- for repo in rabbitmq.repo.refresh %}

rabbitmq/Refresh cache and import the new key for {{ repo }}:
  cmd.run:
    - name: yum -q makecache -y --disablerepo='*' --enablerepo='{{ repo }}'
    - onchanges:
      - file: rabbitmq/Install GPG key file
    - onlyif: test -f {{ rabbitmq.repo.file }}

  {%- endfor %}

{%- endif %}

rabbitmq/Install dependencies:
  pkg.latest:
    - pkgs: {{ rabbitmq.dependencies }}
    - onlyif: test ! -f {{ rabbitmq.repo.file }}

rabbitmq/Configure ERLang repo:
  cmd.run:
    - name: {{ rabbitmq.erlang_repo.install }}
    - creates: {{ rabbitmq.erlang_repo.file }}

rabbitmq/Configure official RabbitMQ repo:
  cmd.run:
    - name: {{ rabbitmq.repo.install }}
    - creates: {{ rabbitmq.repo.file }}

{%- for repo in rabbitmq.repo.disable %}

rabbitmq/Disable {{ repo }} repo:
  pkgrepo.managed:
    - name: {{ repo }}
    - enabled: False
    - require:
      - cmd: rabbitmq/Configure official RabbitMQ repo

{%- endfor %}

rabbitmq/Install RabbitMQ server:
  pkg.installed:
    - pkgs: {{ rabbitmq.packages }}
    - require:
      - rabbitmq/Configure ERLang repo
      - rabbitmq/Configure official RabbitMQ repo

rabbitmq/Run RabbitMQ Server:
  service.running:
    - name: {{ rabbitmq.service }}
    - enable: True
    - watch:
      - rabbitmq/Install RabbitMQ server
