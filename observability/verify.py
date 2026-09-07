"""Verify a provisioned dashboard and actual JMeter metrics through Grafana."""
import urllib.request,urllib.parse,base64,json,time,os
base=os.getenv('GRAFANA_URL','http://127.0.0.1:3001')
credentials=os.getenv('GRAFANA_USER','demo')+':'+os.getenv('GRAFANA_PASSWORD','local-demo-only')
headers={'Authorization':'Basic '+base64.b64encode(credentials.encode()).decode()}
def get(path):
 return json.load(urllib.request.urlopen(urllib.request.Request(base+path,headers=headers),timeout=5))
for attempt in range(30):
 try:
  assert get('/api/health')['database']=='ok'
  assert get('/api/dashboards/uid/ledgerguard')['dashboard']['panels']
  query=urllib.parse.urlencode({'db':'jmeter','q':"SELECT sum(count) FROM jmeter WHERE application='ledgerguard' AND transaction='all' AND time > now()-15m"})
  result=get('/api/datasources/proxy/uid/jmeter-influx/query?'+query)
  value=result['results'][0]['series'][0]['values'][0][1]
  assert value>0
  print('Grafana dashboard, datasource and JMeter metrics verified:',value,'samples');break
 except Exception:
  if attempt==29:raise
  time.sleep(2)
