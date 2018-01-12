node['blockdevice_test'].each do |name, resources|
  resources.each do |resource_type, params|
    send(resource_type, name) do
      params.each do |property_name, property_value|
        send(property_name, property_value)
      end
    end
  end
end
