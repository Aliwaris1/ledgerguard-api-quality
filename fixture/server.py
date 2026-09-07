"""Local, in-memory API fixture. Not a production service; all money is fictional."""
import json, secrets, threading, uuid, argparse, socketserver
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs
LOCK=threading.RLock()
SESSIONS={}
STATES={}
def uid(): return uuid.uuid4().hex
class ApiError(Exception):
    def __init__(self,status,code): self.status,self.code=status,code
def require(ok,status,code):
    if not ok: raise ApiError(status,code)
def integer(value): return type(value) is int and 0 < value <= 1000000
def owned(items,key,owner):
    require(key in items,404,"NOT_FOUND")
    item=items[key]
    require(item["owner"]==owner,403,"FORBIDDEN")
    return item
class Handler(BaseHTTPRequestHandler):
    def log_message(self,*args): pass
    def do_GET(self): self.handle_request()
    def do_POST(self): self.handle_request()
    def do_DELETE(self): self.handle_request()
    def handle_request(self):
        try:
            length=int(self.headers.get('Content-Length',0))
            require(0 <= length <= 65536,413,"BODY_TOO_LARGE")
            body=json.loads(self.rfile.read(length)) if length else {}
            require(isinstance(body,dict),400,"INVALID_JSON")
            path=urlparse(self.path).path
            with LOCK:
                if path=='/health' and self.command=='GET': result=(200,{"status":"UP"})
                elif path=='/auth/token' and self.command=='POST':
                    require(body.get('username') in ('alice','bob') and body.get('password')=='demo-password',401,'INVALID_CREDENTIALS')
                    tenant=body.get('tenant','demo')
                    require(isinstance(tenant,str) and 1 <= len(tenant) <= 100,422,'INVALID_TENANT')
                    token=secrets.token_hex(24)
                    SESSIONS[token]=(tenant,body['username'])
                    result=(200,{'token':token})
                else:
                    auth=self.headers.get('Authorization','')
                    require(auth.startswith('Bearer ') and auth[7:] in SESSIONS,401,'UNAUTHORIZED')
                    tenant,owner=SESSIONS[auth[7:]]
                    state=STATES.setdefault(tenant,new_state())
                    result=route(state,owner,self.command,path,body,self.headers,parse_qs(urlparse(self.path).query))
            status,payload=result
        except ApiError as e: status,payload=e.status,{'error':e.code}
        except (ValueError,TypeError): status,payload=400,{'error':'INVALID_JSON'}
        encoded=json.dumps(payload).encode()
        self.send_response(status); self.send_header('Content-Type','application/json')
        self.send_header('Content-Length',str(len(encoded))); self.end_headers();self.wfile.write(encoded)
def new_state(): return {'accounts':{},'transfers':{},'keys':{}}
def route(s,owner,method,path,b,h,q):
    parts=path.strip('/').split('/')
    if method=='POST' and path=='/accounts':
        require(b.get('currency') in ('EUR','USD'),422,'INVALID_CURRENCY')
        item={'id':uid(),'owner':owner,'currency':b['currency'],'balanceCents':0,'status':'OPEN'}
        s['accounts'][item['id']]=item;return 201,item
    if method=='GET' and path=='/accounts': return 200,{'items':[a for a in s['accounts'].values() if a['owner']==owner]}
    if len(parts)>=2 and parts[0]=='accounts':
        item=owned(s['accounts'],parts[1],owner)
        if len(parts)==2 and method=='GET': return 200,item
        if len(parts)==3 and parts[2]=='fund' and method=='POST':
            require(integer(b.get('amountCents')),422,'INVALID_AMOUNT')
            item['balanceCents']+=b['amountCents'];return 200,item
    if method=='POST' and path=='/transfers':
        key=h.get('Idempotency-Key');require(bool(key),400,'IDEMPOTENCY_KEY_REQUIRED')
        cache_key=(owner,key)
        if cache_key in s['keys']:
            previous,item=s['keys'][cache_key];require(previous==b,409,'IDEMPOTENCY_CONFLICT');return 200,item
        source=owned(s['accounts'],b.get('sourceId'),owner)
        target=owned(s['accounts'],b.get('targetId'),owner)
        require(source['id']!=target['id'],422,'SAME_ACCOUNT')
        require(source['currency']==target['currency'],422,'CURRENCY_MISMATCH')
        require(integer(b.get('amountCents')),422,'INVALID_AMOUNT')
        require(source['balanceCents']>=b['amountCents'],409,'INSUFFICIENT_FUNDS')
        source['balanceCents']-=b['amountCents'];target['balanceCents']+=b['amountCents']
        item={'id':uid(),'owner':owner,'sourceId':source['id'],'targetId':target['id'],'amountCents':b['amountCents'],'status':'SETTLED'}
        s['transfers'][item['id']]=item;s['keys'][cache_key]=(b.copy(),item);return 201,item
    if method=='GET' and path=='/transfers': return 200,{'items':[t for t in s['transfers'].values() if t['owner']==owner]}
    if len(parts)>=2 and parts[0]=='transfers':
        item=owned(s['transfers'],parts[1],owner)
        if len(parts)==2 and method=='GET': return 200,item
        if len(parts)==3 and parts[2]=='reverse' and method=='POST':
            require(item['status']=='SETTLED',409,'ALREADY_REVERSED')
            source=s['accounts'][item['sourceId']];target=s['accounts'][item['targetId']]
            require(target['balanceCents']>=item['amountCents'],409,'INSUFFICIENT_REVERSAL_FUNDS')
            target['balanceCents']-=item['amountCents'];source['balanceCents']+=item['amountCents'];item['status']='REVERSED';return 200,item
    raise ApiError(404,'NOT_FOUND')

class LocalServer(ThreadingHTTPServer):
    def server_bind(self):
        # No reverse DNS lookup: fixture startup is deterministic offline.
        socketserver.TCPServer.server_bind(self)
        self.server_name = self.server_address[0]
        self.server_port = self.server_address[1]
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--host',default='127.0.0.1');p.add_argument('--port',type=int,default=8080)
    a=p.parse_args();server=LocalServer((a.host,a.port),Handler)
    print(server.server_address[1],flush=True);server.serve_forever()
