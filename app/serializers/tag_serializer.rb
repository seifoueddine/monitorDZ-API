class TagSerializer
  include FastJsonapi::ObjectSerializer
  attributes :name, :status
end
