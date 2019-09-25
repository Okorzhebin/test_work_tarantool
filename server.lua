function message(str, key, value)
    if str == 'inserted' then

		resp = {
			status = 200,
            headers = { ['content-type'] = 'application/json' },
            body = json.encode({['key'] =  key, ['value'] = (value)})

		}

        log.info(resp)
        return resp
    end
	if str == 'updated' then 
		resp = {
			status = 200,
            headers = { ['content-type'] = 'application/json' },
			body = json.encode({['updated key'] =  key, ['value '] = (value)})
		}

        log.info(resp)
        return resp
    end
	if str == 'deleted' then 
		resp = {
			status = 200,
            headers = { ['content-type'] = 'application/json' },
			body = json.encode('deleted key:' .. key)
		}

        log.info(resp)
        return resp
    end
	if str == 'key exist' then
		resp = {
			status = 409,
            headers = { ['content-type'] = 'application/json' },
			body = json.encode('key:' .. key.. ' exist')
		}

        log.info(resp)
        return resp
	end
	if str == 'no body' then
		resp = {
			status = 400,
            headers = { ['content-type'] = 'application/json' },
			body = json.encode('body incorrect')
		}

        log.info(resp)
        return resp
	end
	if str == 'no key' then
		resp = {
			status = 404,
            headers = { ['content-type'] = 'application/json' },
			body = json.encode('no key: ' .. key)
		}

        log.info(resp)
        return resp
	end


end
function POST_req(req)


        local key = req:param('key')
        local value = req:param('value')
    
        log.info('get msg, key: ' .. key )
        --log.info(key, value)
        -- json есть, проверяем наличие поля ключ
        if key ~= nill and type (key) == 'string' then
            log.info('get key')
            -- проверяем существование ключа
            if box.space.tester.index.primary:get{key} == nil then
                log.info('key approved')
                --проверяем наличие value
                if value ~= nil and type (value) == 'table' then
                    log.info('insert key-value')
                    box.space.tester:insert{key, value}
					message('inserted', key , value)
                
                else
                    resp = message('no body')
                end 
			else
                resp = message('key exist', key)
            end
        else
			log.info('no key')
            --resp = message('no key')
        end
    
    
        return resp
end

function PUT_req(req)

        local key = req:stash('id')
        local value = req:param('value')
    
        log.info('get msg, key: ' .. key )
        log.info(type (value) .. tostring (value == nil))
        -- json есть, проверяем наличие поля ключ
        if key ~= nill and type (key) == 'string' then
            log.info('get key')
            -- проверяем существование ключа
            if box.space.tester.index.primary:get{key} ~= nil then
                log.info('key approved')
                --проверяем наличие value
                if value ~= nil and type (value) == 'table' then
                    log.info('updated key-value')
                    box.space.tester:update(key, {{'=', 2, value}})
					message('updated', key , value)
                
                else
                    resp = message('no body')
                end 
			else
                resp = message('no key', key)
            end
        else
			log.info('no key')
            --resp = message('no key')
        end
    
    
        return resp
end
function GET_req(req)

        local key = req:stash('id')
        
    
        log.info('get msg, key: ' .. key )
        --log.info(key, value)
        -- json есть, проверяем наличие поля ключ
        if key ~= nill and type (key) == 'string' then
            log.info('get key')
            -- проверяем существование ключа
            if box.space.tester.index.primary:get{key} ~= nil then
                log.info('key approved')
                	value = box.space.tester:get{key}
                	value = value[2]

                resp = {
						status = 200,
						headers = { ['content-type'] = 'application/json' },
						body = json.encode({key = key, value = value})
					}


			else
                resp = message('no key', key)
            end
        else
			log.info('no key')
            --resp = message('no key')
        end
    
    
        return resp
end

function DELETE_req(req)

        local key = req:stash('id')
        
    
        log.info('get msg, key: ' .. key )
        --log.info(key, value)
        -- json есть, проверяем наличие поля ключ
        if key ~= nill and type (key) == 'string' then
            log.info('get key')
            -- проверяем существование ключа
            if box.space.tester.index.primary:get{key} ~= nil then
                log.info('key approved')
                	box.space.tester:delete(key)
                	message('deleted', key)

			else
                resp = message('no key', key)
            end
        else
			log.info('no key')
            --resp = message('no key')
        end
    
    
        return resp
end


    json=require('json')
    log = require('log')


    server = require('http.server').new('0.0.0.0', 8088, { charset = "application/json" , log_requests = true} ) -- анализировать связь с *:8080
    server:route({ path = '/kv/' , method = 'POST' }, POST_req)
	server:route({ path = '/kv/:id' , method = 'PUT' }, PUT_req)
	server:route({ path = '/kv/:id' , method = 'GET' }, GET_req)
	server:route({ path = '/kv/:id' , method = 'DELETE' }, DELETE_req)
    server:start()


    print('start http')


    box.cfg{listen = 3301
            log = 'server.log',
            pid_file = 'server.pid'}
    box.schema.user.grant('guest', 'read,write,execute', 'universe')
    print('prestart tarantool')
    box.once("bootstrap", function()
    s = box.schema.space.create('tester', {if_not_exists = true})


    s:create_index(
    "primary", {type = 'hash', parts = {1, 'string'}})


    require('console').start()

    end)
    box.schema.user.grant('guest', 'read,write,execute', 'universe')


    --log.info('start tarantool')
    print('start tarantool')
    
