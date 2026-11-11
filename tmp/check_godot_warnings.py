import socket,json,time,pathlib
root=pathlib.Path.cwd(); s=socket.create_connection(('127.0.0.1',6005));s.settimeout(0.02)
def send(m):
 b=json.dumps(m).encode();s.sendall(b'Content-Length: '+str(len(b)).encode()+b'\r\n\r\n'+b)
buf=b'';diags={}
def drain(seconds):
 global buf
 end=time.time()+seconds
 while time.time()<end:
  try: buf+=s.recv(1048576)
  except socket.timeout: continue
  while b'\r\n\r\n' in buf:
   h,rest=buf.split(b'\r\n\r\n',1);n=int(h.split(b'Content-Length: ')[1].split(b'\r\n')[0])
   if len(rest)<n:break
   m=json.loads(rest[:n]);buf=rest[n:]
   if m.get('method')=='textDocument/publishDiagnostics':diags[m['params']['uri']]=m['params']['diagnostics']
send({'jsonrpc':'2.0','id':1,'method':'initialize','params':{'processId':None,'rootUri':root.as_uri(),'capabilities':{}}});drain(1)
send({'jsonrpc':'2.0','method':'initialized','params':{}})
for p in root.joinpath('Scripts').rglob('*.gd'):
 send({'jsonrpc':'2.0','method':'textDocument/didOpen','params':{'textDocument':{'uri':p.as_uri(),'languageId':'gdscript','version':1,'text':p.read_text(encoding='utf-8-sig')}}})
 drain(.015)
drain(3)
pathlib.Path('tmp/godot_diagnostics.json').write_text(json.dumps(diags,indent=2))
for uri,items in diags.items():
 for d in items:print(uri.split('/proyecto-lazaro/')[-1],d['range']['start']['line']+1,d.get('code'),d['message'])
print('FILES',len(diags),'ISSUES',sum(map(len,diags.values())))
