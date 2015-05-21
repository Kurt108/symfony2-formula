{% from "symfony2/map.jinja" import symfony2 with context %}

include:
{% if symfony2.database == "mysql" %}
  - php.ng.mysql
{%- if symfony2.db_host == '127.0.0.1' or symfony2.db_host == 'localhost' %}
  - mysql.server
  - mysql.python
  - mysql.user
  - mysql.database
{% endif %}
{% endif %}
  - nginx.ng.service
  - php.composer
{% if symfony2.database == "sqlite" %}
  - php.ng.sqlite

sqlite3:
  pkg.installed
{% endif %}


extend:
  nginx_service:
    service:
      - watch:
        - file: symfony2-vhost-config
      - require:
        - file: symfony2-vhost-config





{{ symfony2.doc_root }}:
  file.directory:
    - name: {{ symfony2.doc_root }}
    - user: {{ symfony2.user }}
    - group: {{ symfony2.user }}
    - makedirs: True






symfony2-vhost-config:
  file.managed:
    - name: /etc/nginx/conf.d/symfony2
    - source: salt://symfony2/files/nginx-config.conf
    - template: jinja
    - context:
        symfony2: {{ symfony2 }}





parameters.yml:
  file.managed:
    - name: {{ symfony2.doc_root  }}/{{ symfony2.app }}/app/config/parameters.yml.dist
    - source: salt://symfony2/files/parameters.yml.tmpl
    - template: jinja
    - user: {{ symfony2.user }}
    - group: {{ symfony2.user }}
    - context:
        symfony2: {{ symfony2 }}


install_symfony2:
  cmd.wait:
    - name: composer install --no-interaction
    - cwd: {{ symfony2.doc_root  }}/{{symfony2.app }}
    - user: {{ symfony2.user }}
    - watch:
      - file: parameters.yml
    - require:
      - sls: php.composer


{% if  symfony2.repository == false %}
get_symfony2:
  cmd.run:
    - name: composer create-project --no-progress --no-interaction symfony/framework-standard-edition {{ symfony2.app }}
    - cwd: {{ symfony2.doc_root  }}
    - creates: {{ symfony2.doc_root  }}/{{symfony2.app }}
    - user: {{ symfony2.user }}
    - require:
      - sls: php.composer
      {% if symfony2.database == "mysql" %}
      - sls: php.ng.mysql
      {%- if symfony2.db_host == '127.0.0.1' or symfony2.db_host == 'localhost' %}
      - sls: mysql.server
      - sls: mysql.python
      - sls: mysql.user
      - sls: mysql.database
      {% endif %}
      {% endif %}
      {% if symfony2.database == "sqlite" %}
      - sls: php.ng.sqlite
      - pkg: sqlite3
      {% endif %}


remove_parameters.yml:
  cmd.wait:
    - name: rm app/config/parameters.yml
    - cwd: {{ symfony2.doc_root  }}/{{symfony2.app }}
    - onlyif:
      - test -x app/config/parameters.yml
    - watch:
      - cmd: get_symfony2
    - require:
      - cmd: get_symfony2
    - require_in:
      - cmd: install_symfony2
      - file: parameters.yml

{% elif  symfony2.repository %}





get_symfony2:
  git.latest:
    - name: git@github.com:JaXt0r/diamantweg-buddhismus.de.git
    - target: {{ symfony2.doc_root  }}/symfony2
    - user: {{ symfony2.user }}
    - require:
      - pkg: git
      - file: github_sshpriv
      - file: github_sshpub
      - ssh_known_hosts: github
    - require_in:
      -  cmd: install_symfony2
      -  file: parameters.yml


www-data:
  user.present:
    - shell: /bin/bash
    - home: {{ symfony2.doc_root }}
    - require_in:
      - file: github_sshpriv
      - file: github_sshpub
      - ssh_known_hosts: github

ssh-folder:
  file.directory:
    - name: {{ symfony2.doc_root }}/.ssh
    - user: {{ symfony2.user }}
    - group: {{ symfony2.user }}
    - mode: 0700
    - require_in:
      - file: github_sshpriv
      - file: github_sshpub
      - ssh_known_hosts: github

github:
  ssh_known_hosts:
    - present
    - name: github.com
    - user: {{ symfony2.user }}
    - enc: ssh-rsa
    - fingerprint: {{ salt['pillar.get']('github:fingerprint') }}

github_sshpriv:
  file.managed:
    - name: {{ symfony2.doc_root }}/.ssh/id_rsa
    - user: {{ symfony2.user }}
    - group: {{ symfony2.user }}
    - mode: 0600
    - contents_pillar: github:sshpriv

github_sshpub:
  file.managed:
    - name: {{ symfony2.doc_root }}/.ssh/id_rsa.pub
    - user: {{ symfony2.user }}
    - group: {{ symfony2.user }}
    - mode: 0600
    - contents_pillar: github:sshpub
    - require:
      - file: github_sshpriv


git:
  pkg.installed





{% endif %}