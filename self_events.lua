return {
	-- Called before law will be revoked.
	--	Contains:
	--		law_id :: uint: The index of the law.
	on_pre_revoke_law = script.generate_event_name(),

	-- Called when a law is passed.
	--	Contains:
	--		law_id :: uint: The index of the law.
	on_passed_law = script.generate_event_name()
}
