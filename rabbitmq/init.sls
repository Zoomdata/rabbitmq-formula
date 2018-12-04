{%- from 'rabbitmq/map.jinja' import rabbitmq %}

rabbitmq/Install dependencies:
  pkg.latest:
    - pkgs: {{ rabbitmq.dependencies }}

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
    - onchanges:
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
