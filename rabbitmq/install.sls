{%- from 'rabbitmq/map.jinja' import rabbitmq %}

{%- for component_repo in (rabbitmq.erlang_repo, rabbitmq.repo) %}

  {%- if 'key_url'  in component_repo and
         'key_file' in component_repo and
         'refresh'  in component_repo %}

# These states for handling the GPG key are specific to YUM/RedHat.
# The APT on Debian derivatives doesn't need any special care.

rabbitmq/Install {{ salt['file.basename'](component_repo.key_file) }}:
  file.managed:
    - name: {{ component_repo.key_file }}
    - source: {{ component_repo.key_url }}
    - skip_verify: True
    - user: root
    - group: root
    - mode: 0644

    {%- for repo in component_repo.refresh %}

rabbitmq/Refresh cache and import the new key for {{ repo }}:
  cmd.run:
    - name: yum -q makecache -y --disablerepo='*' --enablerepo='{{ repo }}'
    - onchanges:
      - file: {{ component_repo.key_file }}
    - onlyif: test -f {{ component_repo.file }}

    {%- endfor %}

  {%- endif %}

{%- endfor %}

rabbitmq/Install dependencies:
  pkg.latest:
    - pkgs: {{ rabbitmq.dependencies }}
    - onlyif: test ! -f {{ rabbitmq.repo.file }}

rabbitmq/Configure Erlang repo:
  cmd.run:
    - name: {{ rabbitmq.erlang_repo.install }}
    - creates: {{ rabbitmq.erlang_repo.file }}

rabbitmq/Configure official RabbitMQ repo:
  cmd.run:
    - name: {{ rabbitmq.repo.install }}
    - creates: {{ rabbitmq.repo.file }}

{%- for component_repo in (rabbitmq.erlang_repo, rabbitmq.repo) %}

  {%- for repo in component_repo.disable %}

rabbitmq/Disable {{ repo }} repo:
  pkgrepo.managed:
    - name: {{ repo }}
    - enabled: False

  {%- endfor %}

{%- endfor %}

rabbitmq/Install RabbitMQ server:
  pkg.installed:
    - pkgs: {{ rabbitmq.packages }}
    - require:
      - rabbitmq/Configure Erlang repo
      - rabbitmq/Configure official RabbitMQ repo

rabbitmq/Run RabbitMQ Server:
  service.running:
    - name: {{ rabbitmq.service }}
    - enable: True
    - watch:
      - rabbitmq/Install RabbitMQ server
