#!/cvmfs/soft.computecanada.ca/gentoo/2023/x86-64-v3/usr/bin/python
import yaml
import glob
import os
import shutil
import re

# This script is meant to convert a yaml file with values tempalted as {{XXXX}}
# by recovering values from the environment and writing a proper yaml file.
# It is used for creating yaml files on the fly for
# https://jupyter-app-launcher.readthedocs.io/en/latest/usage.html

templates_path = os.getenv('JUPYTER_APP_LAUNCHER_TEMPLATES_PATH')
dst_path = os.getenv('JUPYTER_APP_LAUNCHER_PATH')
if not templates_path or not os.path.isdir(templates_path):
    exit(1)

hostname = os.getenv('HOSTNAME')
cc_cluster = os.getenv('CC_CLUSTER')
if cc_cluster == 'magic_castle':
    os.environ['METRIX_HOST'] = '.'.join(['metrix'] + hostname.split('.')[2:])

os.chdir(templates_path)
# copy yml and yaml files as is
for file in glob.glob('*.yml') + glob.glob('*.yaml'):
    shutil.copy(file, dst_path)

# read yml.tmpl and yaml.tmpl files to parse them and replace their strings
for file in glob.glob('*.yml.tmpl'):
    with open(file, 'r') as f:
        data = yaml.load(f, Loader=yaml.SafeLoader)
        # replace {{XXXX}} by os.getenv(XXXX, '')
        for item_dict in data:
            for k,v in item_dict.items():
                if isinstance(v, str):
                    v_new = v
                    matches = re.findall("{{(.*?)}}", v)
                    for match in matches:
                        env_val = os.getenv(match, '')
                        v_new = v_new.replace("{{%s}}" % match, env_val)
                    item_dict[k] = v_new
        with open(os.path.join(dst_path, file.replace('.tmpl','')), 'w') as f_new:
            yaml.dump(data, f_new)
