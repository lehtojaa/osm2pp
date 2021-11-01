require "helpers"

local tables = {}

-- Keys to include for further checking.  Not all values from each key will be preserved
local poi_first_level_keys = {
    'building',
    'shop',
    'amenity',
	'tourism',
	'aeroway'
}

local is_first_level_poi = make_check_in_list_func(poi_first_level_keys)


function building_poi(object)
    local bldg_name = get_name(object.tags)
    if (bldg_name ~= '' or object.tags.operator) then
        return true
    end

    return false
end



local function get_osm_type_subtype(object)
    local osm_type_table = {}

    if object.tags.shop then
        osm_type_table['osm_type'] = 'shop'
        osm_type_table['osm_subtype'] = object:grab_tag('shop')
    elseif object.tags.amenity then
        osm_type_table['osm_type'] = 'amenity'
        osm_type_table['osm_subtype'] = object:grab_tag('amenity')
    elseif object.tags.building then
        osm_type_table['osm_type'] = 'building'
        osm_type_table['osm_subtype'] = object:grab_tag('building')
    elseif object.tags.tourism then
        osm_type_table['osm_type'] = 'tourism'
        osm_type_table['osm_subtype'] = object:grab_tag('tourism')
	elseif object.tags.aeroway then
		osm_type_table['osm_type'] = 'aeroway'
		osm_type_table['osm_subtype'] = object:grab_tag('aeroway')
    else
        -- Cannot be NULL
        osm_type_table['osm_type'] = 'Unknown'
        osm_type_table['osm_subtype'] = 'Unknown'
    end

    return osm_type_table
end

tables.poi_point = osm2pgsql.define_table({
    name = 'poi_point',
    schema = schema_name,
    ids = { type = 'node', id_column = 'osm_id' },
    columns = {
        { column = 'osm_type',     type = 'text', not_null = true },
        { column = 'osm_subtype',     type = 'text', not_null = true },
        { column = 'name',     type = 'text' },
		{ column = 'opening_hours',   type = 'text' },
		{ column = 'phone',   type = 'text' },
		{ column = 'email',   type = 'text' },
		{ column = 'url',      type = 'text' },
		{ column = 'website',      type = 'text' }, 
        { column = 'housenumber', type = 'text'},
        { column = 'street',     type = 'text' },
        { column = 'city',     type = 'text' },
        { column = 'state', type = 'text'},
        { column = 'postcode', type = 'text'},
        { column = 'address', type = 'text', not_null = true},
        { column = 'operator', type = 'text'},
        { column = 'geom',     type = 'point' , projection = srid},
    }
})


tables.poi_line = osm2pgsql.define_table({
    name = 'poi_line',
    schema = schema_name,
    ids = { type = 'way', id_column = 'osm_id' },
    columns = {
        { column = 'osm_type',     type = 'text', not_null = true },
        { column = 'osm_subtype',     type = 'text', not_null = true },
        { column = 'name',     type = 'text' },
		{ column = 'opening_hours',   type = 'text' },
		{ column = 'phone',   type = 'text' },
		{ column = 'email',   type = 'text' },
		{ column = 'url',      type = 'text' },
		{ column = 'website',      type = 'text' }, 
        { column = 'housenumber', type = 'text'},
        { column = 'street',     type = 'text' },
        { column = 'city',     type = 'text' },
        { column = 'state', type = 'text'},
        { column = 'postcode', type = 'text'},
        { column = 'address', type = 'text', not_null = true},
        { column = 'operator', type = 'text'},
        { column = 'geom',     type = 'linestring' , projection = srid},
    }
})

tables.poi_polygon = osm2pgsql.define_table({
    name = 'poi_polygon',
    schema = schema_name,
    ids = { type = 'way', id_column = 'osm_id' },
    columns = {
        { column = 'osm_type',     type = 'text', not_null = true },
        { column = 'osm_subtype',     type = 'text', not_null = true },
        { column = 'name',     type = 'text' },
		{ column = 'opening_hours',   type = 'text' },
		{ column = 'phone',   type = 'text' },
		{ column = 'email',   type = 'text' },
		{ column = 'url',      type = 'text' },
		{ column = 'website',      type = 'text' }, 
        { column = 'housenumber', type = 'text'},
        { column = 'street',     type = 'text' },
        { column = 'city',     type = 'text' },
        { column = 'state', type = 'text'},
        { column = 'postcode', type = 'text'},
        { column = 'address', type = 'text', not_null = true},
        { column = 'operator', type = 'text'},
        { column = 'member_ids', type = 'jsonb'},
        { column = 'geom',     type = 'multipolygon' , projection = srid},
    }
})



function poi_process_node(object)
    -- Quickly remove any that don't match the 1st level of checks
    if not is_first_level_poi(object.tags) then
        return
    end

    

    if (object.tags.building and not building_poi(object)) then
        return
    end


  
    local osm_types = get_osm_type_subtype(object)

    local name = get_name(object.tags)
	local opening_hours = object.tags['opening_hours']
	local phone = object.tags['phone']
	local email = object.tags['email']
	local url = object.tags['url'] 
	local website = object.tags['website'] 
    local housenumber  = object.tags['addr:housenumber']
    local street = object.tags['addr:street']
    local city = object.tags['addr:city']
    local state = object.tags['addr:state']
    local postcode = object.tags['addr:postcode']
    local address = get_address(object.tags)

    local operator  = object:grab_tag('operator')

    tables.poi_point:add_row({
        osm_type = osm_types.osm_type,
        osm_subtype = osm_types.osm_subtype,
        name = name,
		opening_hours = opening_hours,
		phone = phone,
		email = email,
		url = url, 
		website = website, 
        housenumber = housenumber,
        street = street,
        city = city,
        state = state,
        postcode = postcode,
        address = address,
        operator = operator,
        geom = { create = 'point' }
    })

end


function poi_process_way(object)
    -- Quickly remove any that don't match the 1st level of checks
    if not is_first_level_poi(object.tags) then
        return
    end

    -- Deeper checks for specific osm_type details
    
    

    if (object.tags.building and not building_poi(object)) then
        return
    end


   


    -- Gets osm_type and osm_subtype
    local osm_types = get_osm_type_subtype(object)

    local name = get_name(object.tags)
	local opening_hours = object.tags['opening_hours']
	local phone = object.tags['phone']
	local email = object.tags['email']
	local url = object.tags['url'] 
	local website = object.tags['website'] 
    local housenumber  = object.tags['addr:housenumber']
    local street = object.tags['addr:street']
    local city = object.tags['addr:city']
    local state = object.tags['addr:state']
    local postcode = object.tags['addr:postcode']
    local address = get_address(object.tags)
    local operator  = object:grab_tag('operator')



    if object.is_closed then

        tables.poi_polygon:add_row({
            osm_type = osm_types.osm_type,
            osm_subtype = osm_types.osm_subtype,
            name = name,
			opening_hours = opening_hours,
			phone = phone,
			email = email,
			url = url, 
			website = website, 
            housenumber = housenumber,
            street = street,
            city = city,
            state = state,
            postcode = postcode,
            address = address,
            operator = operator,
            geom = { create = 'area' }
        })
    else
        tables.poi_line:add_row({
            osm_type = osm_types.osm_type,
            osm_subtype = osm_types.osm_subtype,
            name = name,
			opening_hours = opening_hours,
			phone = phone,
			email = email,
			url = url, 
			website = website, 
            housenumber = housenumber,
            street = street,
            city = city,
            state = state,
            postcode = postcode,
            address = address,
            operator = operator,
            geom = { create = 'line' }
        })
    end

end



function poi_process_relation(object)
    -- Quickly remove any that don't match the 1st level of checks
    if not is_first_level_poi(object.tags) then
        return
    end

    -- Deeper checks for specific osm_type details
  

    if (object.tags.building and not building_poi(object)) then
        return
    end

    

    -- Gets osm_type and osm_subtype
    local osm_types = get_osm_type_subtype(object)

    local name = get_name(object.tags)
	local opening_hours = object.tags['opening_hours']
	local phone = object.tags['phone']
	local email = object.tags['email']
	local url = object.tags['url'] 
	local website = object.tags['website'] 
    local housenumber  = object.tags['addr:housenumber']
    local street = object.tags['addr:street']
    local city = object.tags['addr:city']
    local state = object.tags['addr:state']
    local postcode = object.tags['addr:postcode']
    local address = get_address(object.tags)
    local operator  = object:grab_tag('operator')

    local member_ids = osm2pgsql.way_member_ids(object)

    if object.tags.type == 'multipolygon' or object.tags.type == 'boundary' then
        tables.poi_polygon:add_row({
            osm_type = osm_types.osm_type,
            osm_subtype = osm_types.osm_subtype,
            name = name,
			opening_hours = opening_hours,
			phone = phone,
			email = email,
			url = url, 
			website = website, 
			housenumber = housenumber,
            street = street,
            city = city,
            state = state,
            postcode = postcode,
            address = address,
            operator = operator,
            member_ids = member_ids,
            geom = { create = 'area' }
        })
    end

end


if osm2pgsql.process_node == nil then
    -- Change function name here
    osm2pgsql.process_node = poi_process_node
else
    local nested = osm2pgsql.process_node
    osm2pgsql.process_node = function(object)
        local object_copy = deep_copy(object)
        nested(object)
        -- Change function name here
        poi_process_node(object_copy)
    end
end


if osm2pgsql.process_way == nil then
    -- Change function name here
    osm2pgsql.process_way = poi_process_way
else
    local nested = osm2pgsql.process_way
    osm2pgsql.process_way = function(object)
        local object_copy = deep_copy(object)
        nested(object)
        -- Change function name here
        poi_process_way(object_copy)
    end
end


if osm2pgsql.process_relation == nil then
    -- Change function name here
    osm2pgsql.process_relation = poi_process_relation
else
    local nested = osm2pgsql.process_relation
    osm2pgsql.process_relation = function(object)
        local object_copy = deep_copy(object)
        nested(object)
        -- Change function name here
        poi_process_relation(object_copy)
    end
end

