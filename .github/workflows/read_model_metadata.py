import yaml, os
with open('model.yml') as file:
    model = yaml.safe_load(file)

with open(os.environ['GITHUB_OUTPUT'], 'a') as fh:
        print(f'model_binary={model['binary']}', file=fh)
        print(f'model_short_name={model['short_name']}', file=fh)