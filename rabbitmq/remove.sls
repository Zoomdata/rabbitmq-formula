{%- from 'rabbitmq/map.jinja' import rabbitmq %}

rabbitmq/Remove Erlang repository:
  file.absent:
    - name: {{ rabbitmq.erlang_repo.file }}

{%- if 'key_file' in rabbitmq.erlang_repo %}

rabbitmq/Remove Erlang public key:
  file.absent:
    - name: {{ rabbitmq.erlang_repo.key_file }}
    - require:
      - file: rabbitmq/Remove Erlang repository

{%- endif %}

rabbitmq/Remove RabbitMQ repository:
  file.absent:
    - name: {{ rabbitmq.repo.file }}

{%- if 'key_file' in rabbitmq.repo %}

rabbitmq/Remove RabbitMQ public key:
  file.absent:
    - name: {{ rabbitmq.repo.key_file }}
    - require:
      - file: rabbitmq/Remove RabbitMQ repository

{%- endif %}

rabbitmq/Remove the packages:
  pkg.purged:
    - pkgs: {{ rabbitmq.packages|yaml }}
