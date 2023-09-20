require('tables')
require('lists')
require('logger')

local TrustFactory = {}
TrustFactory.__index = TrustFactory

function TrustFactory.trusts(main_job_trust, sub_job_trust)
	if sub_job_trust then
		for role in main_job_trust:get_roles():it() do
			if not role:allows_duplicates() then
				sub_job_trust:blacklist_role(role:get_type())
			end
		end
		for role in sub_job_trust:get_roles():it() do
			if sub_job_trust:is_blacklisted(role:get_type()) then
				sub_job_trust:remove_role(role)
			end
		end
	end
	return main_job_trust, sub_job_trust
end

function TrustFactory.trust_contains_role(trust, r)
	for role in trust:get_roles():it() do
		if role:get_type() == r:get_type() then
			return true
		end
	end
	return false
end

return TrustFactory



