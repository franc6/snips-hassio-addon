import json
import requests
import uuid

class SnipsConsole():
    def __init__(self):
        self.base_url = 'https://external-gateway.snips.ai'
        self.token = None
        self.access_token = None
        self.alias = None
        self.user_id = None
        self.login_retries = 4

    def login(self, email, password):
        if self.user_id is not None and self.alias is not None and self.access_token is not None:
            #warning("Already logged in!")
            return True

        for x in range(0, self.login_retries):
            r = self._post_request('v1/user/auth',
                {'email': email, 'password': password})
            if r.status_code == 200:
                self.token = r.headers.get('Authorization')
                user = json.loads(r.content)['user']
                self.user_id = user['id']
                self.alias = 'sam{}'.format(str(uuid.uuid4())).replace('-', '')[:29]
                r = self._post_request('v1/user/{user_id}/accesstoken' \
                        .format(user_id=self.user_id),
                        {'alias': self.alias})
                self.token = None
                if r.status_code == 201:
                    access_token_info = json.loads(r.content)['token']
                    # Should we do some sanity checking here?
                    # access_token_info['alias'] == self.alias
                    # the payload part of access_token_info['token'] should
                    # have an email key that matches email, and its active key
                    # should be true.
                    self.access_token = access_token_info['token']
                    break
        return self.access_token is not None

    def logout(self):
        if self.user_id is not None and self.alias is not None and self.access_token is not None:
            dr = requests.delete('{base_url}/v1/user/{user_id}/accesstoken/{alias}' \
                .format(base_url=self.base_url, user_id=self.user_id, alias=self.alias),
                headers={ 'Authorization': "JWT {}".format(self.access_token) })
        self.token = None
        self.access_token = None
        self.alias = None
        self.user_id = None

    def download_assistant(self, assistant_id, temp_file):
        r = self._get_request('v3/assistant/{assistant_id}/download' \
            .format(assistant_id=assistant_id), True)
        for chunk in r.iter_content(chunk_size=4096):
            temp_file.write(chunk)
        temp_file.flush()
        return r.status_code == 200

    def get_assistant_list(self):
        assistants = None
        r = self._get_request('v3/assistant?userid={user_id}'.format(user_id=self.user_id), False)
        if r.status_code == 200:
            js = json.loads(r.content)
            assistants = js['assistants']
        return json.dumps(assistants)
        #assistant_id = assistants[0]['id']

    def _get_request(self, url, stream):
        full_url = '{base_url}/{url}'.format(base_url=self.base_url, url=url)
        headers={ 'Accept': '*/*' }
        if self.access_token is not None:
            headers.update({'Authorization': "JWT {}".format(self.access_token)})
        return requests.get(full_url, headers=headers, stream=stream)

    def _post_request(self, url, data):
        full_url = '{base_url}/{url}'.format(base_url=self.base_url, url=url)
        headers={ 'Content-Type': 'application/json', 'Accept': '*/*' }
        if self.access_token is not None:
            headers.update({'Authorization': "JWT {}".format(self.access_token)})
        elif self.token is not None:
            headers.update({'Authorization': "{}".format(self.token)})
        return requests.post(full_url, headers=headers, json=data)


