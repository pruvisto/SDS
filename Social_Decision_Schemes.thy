(*  
  Title:    Social Decision Schemes.thy
  Author:   Manuel Eberl, TU München

  Definitions of Social Decision Schemes, their properties, and related concepts
*)

section \<open>Social Decision Schemes\<close>

theory Social_Decision_Schemes
imports 
  Complex_Main 
  Probability 
  Preference_Profiles
  Order_Predicates
  Missing_PMF
  Stochastic_Dominance
begin

subsection \<open>Basic Social Choice definitions\<close>

text \<open>
  An agenda consists of a finite set of agents and a finite non-empty 
  set of alternatives.
\<close>
locale agenda = 
  fixes agents :: "'agent set" and alts :: "'alt set"
  assumes finite_agents [simp, intro]: "finite agents"
  assumes finite_alts [simp, intro]: "finite alts"
  assumes nonempty_agents [simp]: "agents \<noteq> {}"
  assumes nonempty_alts [simp]: "alts \<noteq> {}"
begin

abbreviation "is_pref_profile \<equiv> pref_profile_wf agents alts"

lemma finite_complete_preorder_on_iff' [simp]:
  "finite_complete_preorder_on alts R \<longleftrightarrow> complete_preorder_on alts R"
  by (simp add: finite_complete_preorder_on_iff)

lemma pref_profile_wfI' [intro?]:
  "(\<And>i. i \<in> agents \<Longrightarrow> complete_preorder_on alts (R i)) \<Longrightarrow>
   (\<And>i. i \<notin> agents \<Longrightarrow> R i = (\<lambda>_ _. False)) \<Longrightarrow> is_pref_profile R"
  by (simp add: pref_profile_wf_def)

lemma is_pref_profile_update [simp,intro]:
  assumes "is_pref_profile R" "complete_preorder_on alts Ri'" "i \<in> agents"
  shows   "is_pref_profile (R(i := Ri'))"
  using assms by (auto intro!: pref_profile_wf_update)

lemma agenda [simp,intro]: "agenda agents alts"
  by (rule agenda_axioms)


subsubsection \<open>Lotteries\<close>

text \<open>
  The set of lotteries, i.e. the probability mass functions on the type @{typ "'alt"}
  whose support is a subset of the alternative set. 
\<close>
abbreviation lotteries where
  "lotteries \<equiv> lotteries_on alts"
  
text \<open>
  The probability that a lottery returns an alternative that is in the given set
\<close>
abbreviation lottery_prob :: "'alt lottery \<Rightarrow> 'alt set \<Rightarrow> real" where
  "lottery_prob \<equiv> measure_pmf.prob"

lemma lottery_prob_alts_superset: "p \<in> lotteries \<Longrightarrow> alts \<subseteq> A \<Longrightarrow> lottery_prob p A = 1"
  by (metis UNIV_I antisym_conv emeasure_pmf ereal_eq_1(1) lotteries_on_def 
            measure_pmf.emeasure_eq_measure measure_pmf.finite_measure_mono
            measure_pmf.prob_le_1 mem_Collect_eq sets_measure_pmf)

lemma lottery_prob_alts: "p \<in> lotteries \<Longrightarrow> lottery_prob p alts = 1"
  by (rule lottery_prob_alts_superset) simp_all


subsubsection \<open>Stochastic dominance\<close>

text \<open>
  Given a preference relation and an alternative, this returns the set of alternatives
  considered to be at least as good as the given alternative.
\<close>
definition preferred_alts :: "'alt relation \<Rightarrow> 'alt \<Rightarrow> 'alt set" where
  "preferred_alts R x = {y\<in>alts. y \<succeq>[R] x}"

lemma preferred_alts_subset_alts: "preferred_alts R x \<subseteq> alts"
  unfolding preferred_alts_def by simp

lemma finite_preferred_alts [simp,intro!]: "finite (preferred_alts R x)"
  unfolding preferred_alts_def by simp

lemma preferred_alts_altdef: 
  assumes "complete_preorder_on alts R"
  shows   "preferred_alts R x = {y. y \<succeq>[R] x}"
proof -
  interpret complete_preorder_on alts R by fact
  from not_outside show ?thesis by (auto simp: preferred_alts_def)
qed

lemma SD_agenda:
  assumes "complete_preorder_on alts R"
  shows   "p \<succeq>[SD(R)] q \<longleftrightarrow> p \<in> lotteries \<and> q \<in> lotteries \<and> 
             (\<forall>x\<in>alts. measure_pmf.prob p (preferred_alts R x) \<ge> 
                         measure_pmf.prob q (preferred_alts R x))"
proof -
  from assms interpret complete_preorder_on alts R .
  have "preferred_alts R x = {y. y \<succeq>[R] x}" for x using not_outside
    by (auto simp: preferred_alts_def)
  thus ?thesis by (simp add: SD_preorder preferred_alts_def)
qed

lemma SD_agendaI [intro?]: 
  assumes "complete_preorder_on alts R" "p \<in> lotteries" "q \<in> lotteries"
  assumes "\<And>x. x \<in> alts \<Longrightarrow>
             measure_pmf.prob p (preferred_alts R x) \<ge> measure_pmf.prob q (preferred_alts R x)"
  shows   "p \<succeq>[SD(R)] q"
  using assms by (simp add: SD_agenda)

lemma SD_agendaD:
  assumes "complete_preorder_on alts R" "p \<succeq>[SD(R)] q"
  shows   "p \<in> lotteries_on alts" "q \<in> lotteries_on alts"
  and     "\<And>x. x \<in> alts \<Longrightarrow>
             measure_pmf.prob p (preferred_alts R x) \<ge> measure_pmf.prob q (preferred_alts R x)"
  using assms by (simp_all add: SD_agenda)


subsubsection \<open>Pareto dominance\<close>

text \<open>
  This captures the notion of Pareto dominance. An alternative @{term x} is Pareto-dominated
  by an alternative @{term y} w.r.t. the preference profile @{term R} if all agents weakly prefer
  @{term y} to @{term x} and at least one agent strictly prefers @{term y} to @{term x}.
\<close>
definition pareto_dom :: "('agent, 'alt) pref_profile \<Rightarrow> 'alt relation" where
  "pareto_dom R x y \<longleftrightarrow> x \<in> alts \<and> y \<in> alts \<and> (\<forall>i\<in>agents. x \<preceq>[R i] y) \<and> (\<exists>i\<in>agents. x \<prec>[R i] y)"

lemma pareto_domI:
  "x \<in> alts \<Longrightarrow> y \<in> alts \<Longrightarrow> (\<And>i. i \<in> agents \<Longrightarrow> x \<preceq>[R i] y) \<Longrightarrow> 
     \<exists>i\<in>agents. \<not>y \<preceq>[R i] x \<Longrightarrow> pareto_dom R x y"
  by (auto simp: pareto_dom_def strongly_preferred_def)

lemma pareto_dom_irrefl [simp]: "\<not>pareto_dom R x x" 
  by (auto simp add: pareto_dom_def strongly_preferred_def)


text \<open>
  A Pareto loser is an alternative that is Pareto-dominated by some other alternative.
\<close>
definition pareto_losers :: "('agent, 'alt) pref_profile \<Rightarrow> 'alt set" where
  "pareto_losers R = {x. \<exists>y. pareto_dom R x y}"


subsubsection \<open>SD efficient lotteries\<close>

text \<open>
  A lottery is considered SD-efficient if there is no other lottery such that 
  all agents weakly prefer the other lottery (w.r.t. stochastic dominance) and at least
  one agent strongly prefers the other lottery.
\<close>
definition SD_efficient :: "('agent, 'alt) pref_profile \<Rightarrow> 'alt lottery \<Rightarrow> bool" where
  "SD_efficient R p \<longleftrightarrow>
     \<not>(\<exists>q\<in>lotteries. (\<forall>i\<in>agents. q \<succeq>[SD(R i)] p) \<and> (\<exists>i\<in>agents. q \<succ>[SD(R i)] p))"

lemma SD_efficientD:
  assumes "SD_efficient R p" "q \<in> lotteries" 
      and "\<And>i. i \<in> agents \<Longrightarrow> q \<succeq>[SD(R i)] p" "\<exists>i\<in>agents. \<not>(q \<preceq>[SD(R i)] p)"
  shows False
  using assms unfolding SD_efficient_def strongly_preferred_def by blast


subsubsection \<open>Favourite alternatives\<close>

definition has_unique_favorites :: "('agent, 'alt) pref_profile \<Rightarrow> bool" where
  "has_unique_favorites R \<longleftrightarrow> (\<forall>i\<in>agents. is_singleton (favorites R i))"
  
lemma unique_favorites:
  assumes "has_unique_favorites R" "i \<in> agents"
  shows   "favorites R i = {favorite R i}"
  using assms unfolding has_unique_favorites_def
  by (auto simp: favorite_def is_singleton_the_elem)


context
  fixes R i assumes wf: "is_pref_profile R" "i \<in> agents"
begin

interpretation R: finite_complete_preorder_on alts "R i"
  using wf by (simp add: pref_profile_wfD)

lemma favorites_altdef':
  "favorites R i = {x\<in>alts. \<forall>y\<in>alts. x \<succeq>[R i] y}"
    unfolding R.Max_wrt_complete_preorder favorites_def
    by (auto simp: strongly_preferred_def)

lemma favorites_subset_alts:
  "favorites R i \<subseteq> alts"
  using assms by (simp add: favorites_altdef')

lemma finite_favorites [simp, intro]:
  "finite (favorites R i)"
  using assms by (simp add: favorites_altdef')

lemma favorites_nonempty:
  "favorites R i \<noteq> {}"
  unfolding favorites_def 
  by (intro R.Max_wrt_nonempty) simp_all

lemma favorite_in_alts:
  assumes "has_unique_favorites R"
  shows   "favorite R i \<in> alts"
  using favorites_subset_alts assms wf by (simp add: unique_favorites)

end


context
  fixes R assumes R: "complete_preorder_on alts R"
begin

interpretation R: complete_preorder_on alts R by fact

lemma Max_wrt_prefs_finite: "finite (Max_wrt R)"
  unfolding R.Max_wrt_preorder by simp

lemma Max_wrt_prefs_nonempty: "Max_wrt R \<noteq> {}"
  using R.Max_wrt_nonempty by simp

lemma maximal_imp_preferred:
  "x \<in> alts \<Longrightarrow> Max_wrt R \<subseteq> preferred_alts R x"
  using R.complete
  by (auto simp: R.Max_wrt_complete_preorder preferred_alts_def strongly_preferred_def)

end

lemma favorites_permute: 
  assumes wf: "is_pref_profile R" "i \<in> agents" and perm: "\<sigma> permutes alts"
  shows   "favorites (permute_profile \<sigma> R) i = \<sigma> ` favorites R i"
proof -
  from assms interpret finite_complete_preorder_on alts "R i" 
    by (simp add: pref_profile_wfD)
  from perm show ?thesis
  unfolding favorites_def
    by (subst Max_wrt_map_relation_bij)
       (simp_all add: permute_profile_def map_relation_def permutes_bij)
qed

end


text \<open>
  In the context of an agenda, a preference profile is a function that 
  assigns to each agent her preference relation (which is a complete preorder)
\<close>


subsection \<open>Social Decision Schemes\<close>

text \<open>
  In the context of an agenda, a Social Decision Scheme (SDS) is a function that 
  maps preference profiles to lotteries on the alternatives.
\<close> 
locale social_decision_scheme = agenda agents alts 
  for agents :: "'agent set" and alts :: "'alt set" +
  fixes sds :: "('agent, 'alt) pref_profile \<Rightarrow> 'alt lottery"
  assumes sds_wf: "is_pref_profile R \<Longrightarrow> sds R \<in> lotteries"


subsection \<open>Anonymity\<close>

text \<open>
  An SDS is anonymous if permuting the agents in the input does not change the result.
\<close>
locale anonymous_sds = social_decision_scheme agents alts sds
  for agents :: "'agent set" and alts :: "'alt set" and sds +
  assumes anonymous: "\<pi> permutes agents \<Longrightarrow> is_pref_profile R \<Longrightarrow> sds (R \<circ> \<pi>) = sds R" 
begin

lemma anonymity_prefs_from_table:
  assumes "prefs_from_table_wf agents alts xs" "prefs_from_table_wf agents alts ys"
  assumes "mset (map snd xs) = mset (map snd ys)"
  shows   "sds (prefs_from_table xs) = sds (prefs_from_table ys)"
proof -
  from prefs_from_table_agent_permutation[OF assms] guess \<pi> .
  with anonymous[of \<pi>, of "prefs_from_table xs"] assms(1) show ?thesis 
    by (simp add: pref_profile_from_tableI)
qed

context
begin
qualified lemma anonymity_prefs_from_table_aux:
  assumes "R1 = prefs_from_table xs" "prefs_from_table_wf agents alts xs"
  assumes "R2 = prefs_from_table ys" "prefs_from_table_wf agents alts ys"
  assumes "mset (map snd xs) = mset (map snd ys)"
  shows   "sds R1 = sds R2" unfolding assms(1,3)
  by (rule anonymity_prefs_from_table) (simp_all add: assms)
end

end


subsection \<open>Neutrality\<close>

text \<open>
  An SDS is neutral if permuting the alternatives in the input does not change the
  result, modulo the equivalent permutation in the output lottery.
\<close>
locale neutral_sds = social_decision_scheme agents alts sds
  for agents :: "'agent set" and alts :: "'alt set" and sds +
  assumes neutral: "\<sigma> permutes alts \<Longrightarrow> is_pref_profile R \<Longrightarrow> 
                        sds (permute_profile \<sigma> R) = map_pmf \<sigma> (sds R)"
begin

text \<open>
  Alternative formulation of neutrality that shows that our definition is 
  equivalent to that in the paper.
\<close>
lemma neutral':
  assumes "\<sigma> permutes alts"
  assumes "is_pref_profile R"
  assumes "a \<in> alts"
  shows   "pmf (sds (permute_profile \<sigma> R)) (\<sigma> a) = pmf (sds R) a"
proof -
  from assms have A: "set_pmf (sds R) \<subseteq> alts" using sds_wf
    by (simp add: lotteries_on_def)
  from assms(1,2) have "pmf (sds (permute_profile \<sigma> R)) (\<sigma> a) = pmf (map_pmf \<sigma> (sds R)) (\<sigma> a)"
    by (subst neutral) simp_all
  also from assms have "\<dots> = pmf (sds R) a"
    by (intro pmf_map_inj') (simp_all add: permutes_inj)
  finally show ?thesis .
qed

end


locale anonymous_neutral_sds = 
  anonymous_sds agents alts sds + neutral_sds agents alts sds
  for agents :: "'agent set" and alts :: "'alt set" and sds
begin

lemma sds_automorphism:
  assumes perm: "\<sigma> permutes alts" and wf: "is_pref_profile R"
  assumes eq: "anonymous_profile agents R = anonymous_profile agents (permute_profile \<sigma> R)"
  shows   "map_pmf \<sigma> (sds R) = sds R"
proof -
  from perm wf have "is_pref_profile (permute_profile \<sigma> R)"
    by (rule pref_profile_wf_permute)
  from anonymous_profile_agent_permutation[OF eq wf this finite_agents] guess \<pi> .
  have "sds (permute_profile \<sigma> R \<circ> \<pi>) = sds (permute_profile \<sigma> R)"
    by (rule anonymous) fact+
  also have "\<dots> = map_pmf \<sigma> (sds R)" by (rule neutral) fact+
  also have "permute_profile \<sigma> R \<circ> \<pi> = R" by fact
  finally show ?thesis ..
qed  

end

subsection \<open>Ex-post efficiency\<close>

locale ex_post_efficient_sds = social_decision_scheme agents alts sds
  for agents :: "'agent set" and alts :: "'alt set" and sds +
  assumes ex_post_efficient: 
    "is_pref_profile R \<Longrightarrow> set_pmf (sds R) \<inter> pareto_losers R = {}"
begin

lemma ex_post_efficient':
  assumes "is_pref_profile R" "pareto_dom R x y"
  shows   "pmf (sds R) x = 0"
  using ex_post_efficient[of R] assms 
  by (auto simp: set_pmf_eq pareto_losers_def)

end



subsection \<open>SD efficiency\<close>

text \<open>
  An SDS is SD-efficient if it returns an SD-efficient lottery for every 
  preference profile, i.e. if the SDS outputs a lottery, it is never the case 
  that there is another lottery that is weakly preferred by all agents an 
  strictly preferred by at least one agent.
\<close>
locale sd_efficient_sds = social_decision_scheme agents alts sds
  for agents :: "'agent set" and alts :: "'alt set" and sds +
  assumes SD_efficient: "is_pref_profile R \<Longrightarrow> SD_efficient R (sds R)"
begin

text \<open>
  An alternative formulation of SD-efficiency that is somewhat more convenient to use.
\<close>
lemma SD_efficient':
  assumes "is_pref_profile R" "q \<in> lotteries"
  assumes "\<And>i. i \<in> agents \<Longrightarrow> q \<succeq>[SD(R i)] sds R" "i \<in> agents" "q \<succ>[SD(R i)] sds R"
  shows   P
  using SD_efficient[of R] sds_wf[OF assms(1)] assms unfolding SD_efficient_def by blast


text \<open>
  Any SD-efficient SDS is also ex-post efficient.
\<close>
sublocale ex_post_efficient_sds
proof unfold_locales
  fix R :: "('agent, 'alt) pref_profile" assume R_wf: "is_pref_profile R"
  def [simp]: p \<equiv> "sds R"
  {
    fix x assume support: "x \<in> set_pmf (sds R)" and loser: "x \<in> pareto_losers R"
    from support sds_wf R_wf have [simp]: "x \<in> alts" by (auto simp: lotteries_on_def)
    from loser obtain y where y: "pareto_dom R x y" by (force simp: pareto_losers_def)
    hence [simp]: "y \<in> alts" by (simp add: pareto_dom_def)

    let ?f = "(\<lambda>z. if z = x then y else z)"
    def q \<equiv> "map_pmf ?f p"
    from sds_wf[OF R_wf] have [simp]: "q \<in> lotteries"
      by (auto simp: lotteries_on_def q_def)
    have prob_q: "lottery_prob q (preferred_alts (R i) z) = 
                    lottery_prob p (?f -` preferred_alts (R i) z)" for i z
      unfolding q_def by simp
    
    from SD_efficient R_wf have "SD_efficient R p" by simp
    hence False
    proof (rule SD_efficientD)
      fix i assume i: "i \<in> agents"
      from i interpret R: finite_complete_preorder_on alts "R i"
        using R_wf by (simp add: pref_profile_wfD)
      
      have "lottery_prob q (preferred_alts (R i) z)  \<ge> lottery_prob p (preferred_alts (R i) z)" 
        if [simp]: "z \<in> alts" for z
      proof (cases "x \<succeq>[R i] z")
        assume not_xz: "\<not>(x \<succeq>[R i] z)"
        hence "lottery_prob p (preferred_alts (R i) z) \<le> 
                 lottery_prob p (?f -` preferred_alts (R i) z)"
          by (intro measure_pmf.finite_measure_mono) (auto simp: preferred_alts_def)
        with prob_q show ?thesis by simp
      next
        assume xz: "x \<succeq>[R i] z"
        with y i have yz: "y \<succeq>[R i] z"
          by (intro R.trans[of z x y]) (auto simp: pareto_dom_def)
        from xz yz have "?f -` preferred_alts (R i) z = preferred_alts (R i) z" 
          by (auto simp: preferred_alts_def)
        with prob_q show ?thesis by simp
      qed
      with sds_wf R_wf show "q \<succeq>[SD(R i)] p" 
        by (intro SD_agendaI) (simp_all add: preferred_alts_def pref_profile_wfD i)
    next
      from y obtain i where i: "i \<in> agents" and y: "y \<succ>[R i] x"
        by (auto simp: pareto_dom_def)
      from i interpret R: finite_complete_preorder_on alts "R i"
        using R_wf by (simp add: pref_profile_wfD)
      from y i have "?f -` preferred_alts (R i) y = {x} \<union> preferred_alts (R i) y"
        by (auto simp: pareto_dom_def strongly_preferred_def R.refl preferred_alts_def)
      also from y i have "lottery_prob p \<dots> = 
            pmf (sds R) x + lottery_prob (sds R) (preferred_alts (R i) y)"
        by (subst measure_Union) 
           (auto simp: pareto_dom_def antisym strongly_preferred_def
                       measure_pmf_single preferred_alts_def)
      finally have "lottery_prob q (preferred_alts (R i) y) > lottery_prob p (preferred_alts (R i) y)"
        using support by (simp add: prob_q pmf_positive)
      with  pref_profile_wfD(1)[OF R_wf i] i
        show "\<exists>i\<in>agents. \<not>p \<succeq>[SD(R i)] q" 
        by (auto intro!: bexI[of _ i] bexI[of _ y] dest!: bspec[of _ _ y] 
                 simp: not_le preferred_alts_altdef R.SD_preorder)
    qed simp_all
  }
  thus "set_pmf (sds R) \<inter> pareto_losers R = {}" by blast
qed  

end



subsection \<open>Weak strategyproofness\<close>

context social_decision_scheme
begin

text \<open>
  The SDS is said to be manipulable for a particular preference profile,
  a particular agent, and a particular alternative preference ordering for that agent
  if the lottery obtained if the agent submits the alternative preferences strictly 
  SD-dominates that obtained if the original preferences are submitted.
  (SD-dominated w.r.t. the original preferences)
\<close>
definition manipulable_profile 
    :: "('agent, 'alt) pref_profile \<Rightarrow> 'agent \<Rightarrow> 'alt relation \<Rightarrow> bool" where 
  "manipulable_profile R i Ri' \<longleftrightarrow> sds (R(i := Ri')) \<succ>[SD (R i)] sds R"

end


text \<open>
  An SDS is weakly strategyproof (or just strategyproof) if it is not manipulable 
  for any combination of preference profiles, agents, and alternative preference relations.
\<close>
locale strategyproof_sds = social_decision_scheme agents alts sds
  for agents :: "'agent set" and alts :: "'alt set" and sds +
  assumes strategyproof: 
    "is_pref_profile R \<Longrightarrow> i \<in> agents \<Longrightarrow> complete_preorder_on alts Ri' \<Longrightarrow>
         \<not>manipulable_profile R i Ri'"  


subsection \<open>Strong strategyproofness\<close>

context social_decision_scheme
begin

text \<open>
  The SDS is said to be strongly strategyproof for a particular preference profile, 
  a particular agent, and a particular alternative preference ordering for that agent
  if the lottery obtained if the agent submits the alternative preferences is
  SD-dominated by the one obtained if the original preferences are submitted.
  (SD-dominated w.r.t. the original preferences)
  
  In other words: the SDS is strategyproof w.r.t the preference profile $R$ and 
  the agent $i$ and the alternative preference relation $R_i'$ if the lottery for 
  obtained for $R$ is at least as good for $i$ as the lottery obtained when $i$ 
  misrepresents her preferences as $R_i'$.
\<close>
definition strongly_strategyproof_profile 
    :: "('agent, 'alt) pref_profile \<Rightarrow> 'agent \<Rightarrow> 'alt relation \<Rightarrow> bool" where
  "strongly_strategyproof_profile R i Ri' \<longleftrightarrow> sds R \<succeq>[SD (R i)] sds (R(i := Ri'))"

lemma strongly_strategyproof_profileI [intro]:
  assumes "is_pref_profile R" "complete_preorder_on alts Ri'" "i \<in> agents"
  assumes "\<And>x. x \<in> alts \<Longrightarrow> lottery_prob (sds (R(i := Ri'))) (preferred_alts (R i) x)
                               \<le> lottery_prob (sds R) (preferred_alts (R i) x)"
  shows "strongly_strategyproof_profile R i Ri'"
  unfolding strongly_strategyproof_profile_def
  by rule (auto intro!: sds_wf assms pref_profile_wf_update pref_profile_wfD[OF assms(1)])

lemma strongly_strategyproof_imp_not_manipulable:
  assumes "strongly_strategyproof_profile R i Ri'"
  shows   "\<not>manipulable_profile R i Ri'"
  using assms unfolding strongly_strategyproof_profile_def manipulable_profile_def
  by (auto simp: strongly_preferred_def)

end


text \<open>
  An SDS is strongly strategyproof if it is strongly strategyproof for all combinations
  of preference profiles, agents, and alternative preference relations.
\<close>
locale strongly_strategyproof_sds = social_decision_scheme agents alts sds
  for agents :: "'agent set" and alts :: "'alt set" and sds +
  assumes strongly_strategyproof: 
    "is_pref_profile R \<Longrightarrow> i \<in> agents \<Longrightarrow> complete_preorder_on alts Ri' \<Longrightarrow>
         strongly_strategyproof_profile R i Ri'"
begin

text \<open>
  Any SDS that is strongly strategyproof is also weakly strategyproof.
\<close>
sublocale strategyproof_sds
  by unfold_locales
     (simp add: strongly_strategyproof_imp_not_manipulable strongly_strategyproof)

end

end