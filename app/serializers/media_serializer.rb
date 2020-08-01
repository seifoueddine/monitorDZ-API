class MediaSerializer
  include FastJsonapi::ObjectSerializer
  attributes :name, :type, :orientation
end
