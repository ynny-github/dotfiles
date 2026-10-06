function install-claude-plugins
    claude plugin marketplace add anthropics/claude-plugins-official
    claude plugin install superpowers@claude-plugins-official
    claude plugin install mattpocock-skills@claude-plugins-official

    claude plugin marketplace add DietrichGebert/ponytail
    claude plugin install ponytail@ponytail
end
