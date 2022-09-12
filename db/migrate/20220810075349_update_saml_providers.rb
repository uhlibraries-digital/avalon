class UpdateSamlProviders < ActiveRecord::Migration[5.2]
  def change
    User.find_each do |user|
      user.update_attribute(:provider, 'SAML')
    end
  end
end
