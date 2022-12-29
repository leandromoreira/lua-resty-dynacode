ActiveAdmin.register Plugin do
  permit_params :name, :phase, :code, :domain_id


  form do |f|
    f.inputs "Plugin" do
      f.input :domain
      f.input :phase, as: :select, collection: ComputingUnit::PHASE_OPTIONS
      f.input :name
      f.input :code, :as => :text
    end
    actions
  end
end
