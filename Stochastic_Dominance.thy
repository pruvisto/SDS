section \<open>Stochastic Dominance\<close>

theory Stochastic_Dominance
imports 
  Complex_Main 
  Probability 
  Preference_Profiles
begin

(* TODO MOVE *)

(* linordered_nonzero_semiring in isabelle-dev *)
lemma indicator_leI:
  "(x \<in> A \<Longrightarrow> y \<in> B) \<Longrightarrow> (indicator A x :: 'a :: linordered_semidom) \<le> indicator B y"
  by (auto simp: indicator_def)

lemma le_diff_iff': "a \<le> c \<Longrightarrow> b \<le> c \<Longrightarrow> c - a \<le> c - b \<longleftrightarrow> b \<le> (a::nat)"
  by linarith

lemma setsum_lessThan_Suc_shift:
  "(\<Sum>i<Suc n. f i) = f 0 + (\<Sum>i<n. f (Suc i))"
  by (induction n) (simp_all add: add_ac)

lemma measure_return_pmf [simp]: "measure_pmf.prob (return_pmf x) A = indicator A x"
proof -
  have "ereal (measure_pmf.prob (return_pmf x) A) = 
          emeasure (measure_pmf (return_pmf x)) A"
    by (simp add: measure_pmf.emeasure_eq_measure)
  also have "\<dots> = ereal (indicator A x)" by (simp add: ereal_indicator)
  finally show ?thesis by simp
qed

lemma (in preorder_on) preferred_alts_refl [simp]: "x \<in> carrier \<Longrightarrow> x \<in> preferred_alts le x"
  by (simp add: preferred_alts_def refl)

lemma measure_pmf_ge_1: "measure_pmf.prob p A \<ge> 1 \<longleftrightarrow> measure_pmf.prob p A = 1"
  by (auto intro!: antisym)

lemma measure_pmf_posI: "x \<in> set_pmf p \<Longrightarrow> x \<in> A \<Longrightarrow> measure_pmf.prob p A > 0"
  using measure_measure_pmf_not_zero[of p A] by (subst zero_less_measure_iff) blast


(* END TODO *)


subsection \<open>Definition of Lotteries\<close>

text \<open>The type of lotteries (a probability mass function)\<close>
type_synonym 'alt lottery = "'alt pmf"

definition lotteries_on :: "'a set \<Rightarrow> 'a lottery set" where
  "lotteries_on A = {p. set_pmf p \<subseteq> A}"

lemma return_pmf_in_lotteries_on [simp,intro]: 
  "x \<in> A \<Longrightarrow> return_pmf x \<in> lotteries_on A"
  by (simp add: lotteries_on_def)


subsection \<open>Definition of Stochastic Dominance\<close>

text \<open>
  This is the definition of stochastic dominance. It lifts a preference relation 
  on alternatives to the stochastic dominance ordering on lotteries.
\<close>
definition SD :: "'alt relation \<Rightarrow> 'alt lottery relation" where
  "p \<succeq>[SD(R)] q \<longleftrightarrow> p \<in> lotteries_on {x. R x x} \<and> q \<in> lotteries_on {x. R x x} \<and> 
      (\<forall>x. R x x \<longrightarrow> measure_pmf.prob p {y. y \<succeq>[R] x} \<ge> 
                       measure_pmf.prob q {y. y \<succeq>[R] x})"


text \<open>
  Stochastic dominance over any relation is a preorder.
\<close>
lemma SD_refl: "p \<preceq>[SD(R)] p \<longleftrightarrow> p \<in> lotteries_on {x. R x x}"
  by (simp add: SD_def)
  
lemma SD_trans [simp, trans]: "p \<preceq>[SD(R)] q \<Longrightarrow> q \<preceq>[SD(R)] r \<Longrightarrow> p \<preceq>[SD(R)] r"
  unfolding SD_def by (auto intro: order.trans)

lemma SD_is_preorder: "preorder_on (lotteries_on {x. R x x}) (SD R)"
  by unfold_locales (auto simp: SD_def intro: order.trans)

context preorder_on
begin

lemma SD_preorder:
   "p \<succeq>[SD(le)] q \<longleftrightarrow> p \<in> lotteries_on carrier \<and> q \<in> lotteries_on carrier \<and> 
      (\<forall>x\<in>carrier. measure_pmf.prob p (preferred_alts le x) \<ge> 
                     measure_pmf.prob q (preferred_alts le x))"
  by (simp add: SD_def preferred_alts_def carrier_eq)  

lemma SD_preorderI [intro?]: 
  assumes "p \<in> lotteries_on carrier" "q \<in> lotteries_on carrier"
  assumes "\<And>x. x \<in> carrier \<Longrightarrow>
             measure_pmf.prob p (preferred_alts le x) \<ge> measure_pmf.prob q (preferred_alts le x)"
  shows   "p \<succeq>[SD(le)] q"
  using assms by (simp add: SD_preorder)

lemma SD_preorderD:
  assumes "p \<succeq>[SD(le)] q"
  shows   "p \<in> lotteries_on carrier" "q \<in> lotteries_on carrier"
  and      "\<And>x. x \<in> carrier \<Longrightarrow>
             measure_pmf.prob p (preferred_alts le x) \<ge> measure_pmf.prob q (preferred_alts le x)"
  using assms unfolding SD_preorder by simp_all

lemma SD_refl' [simp]: "p \<preceq>[SD(le)] p \<longleftrightarrow> p \<in> lotteries_on carrier"
  by (simp add: SD_def carrier_eq)

lemma SD_is_preorder': "preorder_on (lotteries_on carrier) (SD(le))"
  using SD_is_preorder[of le] by (simp add: carrier_eq)

lemma SD_singleton_left:
  assumes "x \<in> carrier" "q \<in> lotteries_on carrier"
  shows   "return_pmf x \<preceq>[SD(le)] q \<longleftrightarrow> (\<forall>y\<in>set_pmf q. x \<preceq>[le] y)"
proof
  assume SD: "return_pmf x \<preceq>[SD(le)] q"
  from assms SD_preorderD(3)[OF SD, of x]
    have "measure_pmf.prob (return_pmf x) (preferred_alts le x) \<le>
            measure_pmf.prob q (preferred_alts le x)" by simp
  also from assms have "measure_pmf.prob (return_pmf x) (preferred_alts le x) = 1"
    by (simp add: indicator_def)
  finally have "AE y in q. y \<succeq>[le] x"
    by (simp add: measure_pmf_ge_1 measure_pmf.prob_eq_1 preferred_alts_def)
  thus "\<forall>y\<in>set_pmf q. y \<succeq>[le] x" by (simp add: AE_measure_pmf_iff)
next
  assume A: "\<forall>y\<in>set_pmf q. x \<preceq>[le] y"
  show "return_pmf x \<preceq>[SD(le)] q"
  proof (rule SD_preorderI)
    fix y assume y: "y \<in> carrier"
    show "measure_pmf.prob (return_pmf x) (preferred_alts le y)
              \<le> measure_pmf.prob q (preferred_alts le y)"
    proof (cases "y \<preceq>[le] x")
      case True
      from True A have "measure_pmf.prob q (preferred_alts le y) = 1"
        by (auto simp: AE_measure_pmf_iff measure_pmf.prob_eq_1 preferred_alts_def intro: trans)
      thus ?thesis by simp
    qed (simp_all add: preferred_alts_def indicator_def measure_nonneg)
  qed (insert assms, simp_all add: lotteries_on_def)
qed

lemma SD_singleton_right:
  assumes x: "x \<in> carrier" and q: "q \<in> lotteries_on carrier"
  shows   "q \<preceq>[SD(le)] return_pmf x \<longleftrightarrow> (\<forall>y\<in>set_pmf q. y \<preceq>[le] x)"
proof safe
  fix y assume SD: "q \<preceq>[SD(le)] return_pmf x" and y: "y \<in> set_pmf q"
  from y assms have [simp]: "y \<in> carrier" by (auto simp: lotteries_on_def)
  
  from y have "0 < measure_pmf.prob q (preferred_alts le y)"
    by (rule measure_pmf_posI) simp_all
  also have "\<dots> \<le> measure_pmf.prob (return_pmf x) (preferred_alts le y)"
    by (rule SD_preorderD(3)[OF SD]) simp_all
  finally show "y \<preceq>[le] x"
    by (auto simp: indicator_def preferred_alts_def split: if_splits)
next
  assume A: "\<forall>y\<in>set_pmf q. y \<preceq>[le] x"
  show "q \<preceq>[SD(le)] return_pmf x"
  proof (rule SD_preorderI)
    fix y assume y: "y \<in> carrier"
    show "measure_pmf.prob q (preferred_alts le y) \<le>
            measure_pmf.prob (return_pmf x) (preferred_alts le y)"
    proof (cases "y \<preceq>[le] x")
      case False
      with A show ?thesis 
        by (auto simp: preferred_alts_def indicator_def measure_le_0_iff 
                       measure_pmf.prob_eq_0 AE_measure_pmf_iff intro: trans)
    qed (simp_all add: indicator_def preferred_alts_def)
  qed (insert assms, simp_all add: lotteries_on_def)
qed

lemma SD_strict_singleton_left:
  assumes "x \<in> carrier" "q \<in> lotteries_on carrier"
  shows   "return_pmf x \<prec>[SD(le)] q \<longleftrightarrow> (\<forall>y\<in>set_pmf q. x \<preceq>[le] y) \<and> (\<exists>y\<in>set_pmf q. (x \<prec>[le] y))"
  using assms by (auto simp add: strongly_preferred_def SD_singleton_left SD_singleton_right)

lemma SD_strict_singleton_right:
  assumes "x \<in> carrier" "q \<in> lotteries_on carrier"
  shows   "q \<prec>[SD(le)] return_pmf x \<longleftrightarrow> (\<forall>y\<in>set_pmf q. y \<preceq>[le] x) \<and> (\<exists>y\<in>set_pmf q. (y \<prec>[le] x))"
  using assms by (auto simp add: strongly_preferred_def SD_singleton_left SD_singleton_right)

lemma SD_singleton [simp]:
  "x \<in> carrier \<Longrightarrow> y \<in> carrier \<Longrightarrow> return_pmf x \<preceq>[SD(le)] return_pmf y \<longleftrightarrow> x \<preceq>[le] y"
  by (subst SD_singleton_left) (simp_all add: lotteries_on_def)

lemma SD_strict_singleton [simp]:
  "x \<in> carrier \<Longrightarrow> y \<in> carrier \<Longrightarrow> return_pmf x \<prec>[SD(le)] return_pmf y \<longleftrightarrow> x \<prec>[le] y"
  by (simp add: strongly_preferred_def)

end

context pref_profile_wf
begin

context
fixes i assumes i: "i \<in> agents"
begin

interpretation Ri: preorder_on alts "R i" by (simp add: i)

lemmas SD_singleton_left = Ri.SD_singleton_left
lemmas SD_singleton_right = Ri.SD_singleton_right
lemmas SD_strict_singleton_left = Ri.SD_strict_singleton_left
lemmas SD_strict_singleton_right = Ri.SD_strict_singleton_right
lemmas SD_singleton = Ri.SD_singleton
lemmas SD_strict_singleton = Ri.SD_strict_singleton

end
end

lemmas (in pref_profile_wf) [simp] = SD_singleton SD_strict_singleton


subsection \<open>Stochastic Dominance for preference profiles\<close>

context pref_profile_wf
begin

lemma SD_pref_profile:
  assumes "i \<in> agents"
  shows   "p \<succeq>[SD(R i)] q \<longleftrightarrow> p \<in> lotteries_on alts \<and> q \<in> lotteries_on alts \<and> 
             (\<forall>x\<in>alts. measure_pmf.prob p (preferred_alts (R i) x) \<ge> 
                         measure_pmf.prob q (preferred_alts (R i) x))"
proof -
  from assms interpret complete_preorder_on alts "R i" by simp
  have "preferred_alts (R i) x = {y. y \<succeq>[R i] x}" for x using not_outside
    by (auto simp: preferred_alts_def)
  thus ?thesis by (simp add: SD_preorder preferred_alts_def)
qed

lemma SD_pref_profileI [intro?]: 
  assumes "i \<in> agents" "p \<in> lotteries_on alts" "q \<in> lotteries_on alts"
  assumes "\<And>x. x \<in> alts \<Longrightarrow>
             measure_pmf.prob p (preferred_alts (R i) x) \<ge> 
             measure_pmf.prob q (preferred_alts (R i) x)"
  shows   "p \<succeq>[SD(R i)] q"
  using assms by (simp add: SD_pref_profile)

lemma SD_pref_profileD:
  assumes "i \<in> agents" "p \<succeq>[SD(R i)] q"
  shows   "p \<in> lotteries_on alts" "q \<in> lotteries_on alts"
  and     "\<And>x. x \<in> alts \<Longrightarrow>
             measure_pmf.prob p (preferred_alts (R i) x) \<ge> 
             measure_pmf.prob q (preferred_alts (R i) x)"
  using assms by (simp_all add: SD_pref_profile)

end


subsubsection \<open>SD efficient lotteries\<close>

definition SD_efficient :: "('agent, 'alt) pref_profile \<Rightarrow> 'alt lottery \<Rightarrow> bool" where
  SD_efficient_auxdef:
    "SD_efficient R p \<longleftrightarrow>
       (let agents = {i. \<exists>x. R i x x};
            alts = {x. \<exists>i. R i x x}
        in \<not>(\<exists>q\<in>lotteries_on alts. (\<forall>i\<in>agents. q \<succeq>[SD(R i)] p) \<and> (\<exists>i\<in>agents. q \<succ>[SD(R i)] p)))"

context pref_profile_wf
begin

text \<open>
  A lottery is considered SD-efficient if there is no other lottery such that 
  all agents weakly prefer the other lottery (w.r.t. stochastic dominance) and at least
  one agent strongly prefers the other lottery.
\<close>
lemma SD_efficient_def:
  "SD_efficient R p \<longleftrightarrow>
     \<not>(\<exists>q\<in>lotteries_on alts. (\<forall>i\<in>agents. q \<succeq>[SD(R i)] p) \<and> (\<exists>i\<in>agents. q \<succ>[SD(R i)] p))"
proof -
  from nonempty_alts obtain x where x: "x \<in> alts" by blast
  from nonempty_agents obtain i where i: "i \<in> agents" by blast
  from x have "i \<in> agents \<longleftrightarrow> (\<exists>x. R i x x)" for i
    by (cases "i \<in> agents") (auto intro!: exI[of _ x] preorder_on.refl[OF prefs_wf'(2)])
  hence A: "agents = {i. \<exists>x. R i x x}" by blast
  have B: "alts = {x. \<exists>i. R i x x}"
  proof safe
    fix x j assume x: "R j x x"
    hence "j \<in> agents" by (cases "j \<in> agents") auto
    with preorder_on.carrier_eq[OF prefs_wf'(2), of j] x show "x \<in> alts" by simp
  qed (auto intro!: exI[of _ i] preorder_on.refl[OF prefs_wf'(2)] i)
  from A B show ?thesis unfolding SD_efficient_auxdef 
    by (simp only: A [symmetric] B [symmetric] Let_def)
qed

lemma SD_inefficientI:
  assumes "q \<in> lotteries_on alts" "\<And>i. i \<in> agents \<Longrightarrow> q \<succeq>[SD(R i)] p" 
          "i \<in> agents" "q \<succ>[SD(R i)] p"
  shows   "\<not>SD_efficient R p" 
  using assms unfolding SD_efficient_def by blast

lemma SD_inefficientI':
  assumes "q \<in> lotteries_on alts" "\<And>i. i \<in> agents \<Longrightarrow> q \<succeq>[SD(R i)] p" 
          "\<exists>i \<in> agents. q \<succ>[SD(R i)] p"
  shows   "\<not>SD_efficient R p" 
  using assms unfolding SD_efficient_def by blast

lemma SD_inefficientE:
  assumes "\<not>SD_efficient R p" 
  obtains q i where
    "q \<in> lotteries_on alts" "\<And>i. i \<in> agents \<Longrightarrow> q \<succeq>[SD(R i)] p" 
    "i \<in> agents" "q \<succ>[SD(R i)] p"
  using assms unfolding SD_efficient_def by blast
   
lemma SD_efficientD:
  assumes "SD_efficient R p" "q \<in> lotteries_on alts" 
      and "\<And>i. i \<in> agents \<Longrightarrow> q \<succeq>[SD(R i)] p" "\<exists>i\<in>agents. \<not>(q \<preceq>[SD(R i)] p)"
  shows False
  using assms unfolding SD_efficient_def strongly_preferred_def by blast

lemma SD_efficient_singleton_iff:
  assumes [simp]: "x \<in> alts"
  shows   "SD_efficient R (return_pmf x) \<longleftrightarrow> x \<notin> pareto_losers R"
proof -
  {
    assume x: "x \<in> pareto_losers R"
    from pareto_losersE[OF x] guess y . note y = this
    from y have "\<not>SD_efficient R (return_pmf x)"
      by (intro SD_inefficientI'[of "return_pmf y"]) (force simp: Pareto_strict_iff)+
  } moreover {
    assume "\<not>SD_efficient R (return_pmf x)"
    from SD_inefficientE[OF this] guess q i . note q = this
    moreover from q obtain y where "y \<in> set_pmf q" "y \<succ>[R i] x"
      by (auto simp: SD_strict_singleton_left)
    ultimately have "y \<succ>[Pareto(R)] x"
      by (fastforce simp: Pareto_strict_iff SD_singleton_left)
    hence "x \<in> pareto_losers R" by simp
  }
  ultimately show ?thesis by blast
qed  

end


subsection \<open>Definition of von Neumann--Morgenstern utility functions\<close>

locale vnm_utility = finite_complete_preorder_on +
  fixes u :: "'a \<Rightarrow> real"
  assumes utility_nonneg: "x \<in> carrier \<Longrightarrow> u x \<ge> 0"
  assumes utility_le_iff: "x \<in> carrier \<Longrightarrow> y \<in> carrier \<Longrightarrow> u x \<le> u y \<longleftrightarrow> x \<preceq>[le] y"
begin

lemma utility_less_iff:
  "x \<in> carrier \<Longrightarrow> y \<in> carrier \<Longrightarrow> u x < u y \<longleftrightarrow> x \<prec>[le] y"
  using utility_le_iff[of x y] utility_le_iff[of y x] 
  by (auto simp: strongly_preferred_def)

text \<open>
  The following lemma allows us to compute the expected utility by summing 
  over all indifference classes, using the fact that alternatives in the same
  indifference class must have the same utility.
\<close>
lemma expected_utility_weak_ranking:
  assumes "p \<in> lotteries_on carrier"
  shows   "measure_pmf.expectation p u =
             (\<Sum>A\<leftarrow>weak_ranking le. u (SOME x. x \<in> A) * measure_pmf.prob p A)"
proof -
  from assms have "measure_pmf.expectation p u = (\<Sum>a\<in>carrier. u a * pmf p a)"
    by (subst integral_measure_pmf[OF finite_carrier])
       (auto simp: lotteries_on_def)
  also have carrier: "carrier = \<Union>set (weak_ranking le)" by (simp add: weak_ranking_Union)
  also from this have finite: "finite A" if "A \<in> set (weak_ranking le)" for A
    using that by (blast intro!: finite_subset[OF _ finite_carrier, of A])
  hence "(\<Sum>a\<in>\<Union>set (weak_ranking le). u a * pmf p a) = 
           (\<Sum>A\<leftarrow>weak_ranking le. \<Sum>a\<in>A. u a * pmf p a)" (is "_ = listsum ?xs")
    using weak_ranking_complete_preorder
    by (subst setsum.Union_disjoint)
       (auto simp: is_weak_ranking_iff disjoint_def setsum.distinct_set_conv_list)
  also have "?xs  = map (\<lambda>A. \<Sum>a\<in>A. u (SOME a. a\<in>A) * pmf p a) (weak_ranking le)"
  proof (intro map_cong HOL.refl setsum.cong)
    fix x A assume x: "x \<in> A" and A: "A \<in> set (weak_ranking le)"
    have "(SOME x. x \<in> A) \<in> A" by (rule someI_ex) (insert x, blast)
    from weak_ranking_eqclass1[OF A x this] weak_ranking_eqclass1[OF A this x] x this A
      have "u x = u (SOME x. x \<in> A)"
      by (intro antisym; subst utility_le_iff) (auto simp: carrier)
    thus "u x * pmf p x = u (SOME x. x \<in> A) * pmf p x" by simp
  qed
  also have "\<dots> = map (\<lambda>A. u (SOME a. a \<in> A) * measure_pmf.prob p A) (weak_ranking le)"
    using finite by (intro map_cong HOL.refl)
                    (auto simp: setsum_right_distrib measure_measure_pmf_finite)
  finally show ?thesis .
qed

end


subsection \<open>Equivalence proof\<close>

text \<open>
  We now show that a lottery is preferred w.r.t. Stochastic Dominance iff
  it yields more expected utility for all compatible utility functions.
\<close>

context finite_complete_preorder_on
begin

abbreviation "is_vnm_utility \<equiv> vnm_utility carrier le"

(* 
  TODO: one direction could probably be generalised to weakly consistent
  utility functions
*)
lemma SD_iff_expected_utilities_le:
  assumes "p \<in> lotteries_on carrier" "q \<in> lotteries_on carrier"
  shows   "p \<preceq>[SD(le)] q \<longleftrightarrow> 
             (\<forall>u. is_vnm_utility u \<longrightarrow> measure_pmf.expectation p u \<le> measure_pmf.expectation q u)"
proof safe 
  fix u assume SD: "p \<preceq>[SD(le)] q" and is_utility: "is_vnm_utility u"
  from is_utility interpret vnm_utility carrier le u .
  def xs \<equiv> "weak_ranking le"
  have le: "is_weak_ranking xs" "le = of_weak_ranking xs"
    by (simp_all add: xs_def weak_ranking_complete_preorder)

  let ?pref = "\<lambda>p x. measure_pmf.prob p {y. x \<preceq>[le] y}" and 
      ?pref' = "\<lambda>p x. measure_pmf.prob p {y. x \<prec>[le] y}"
  def f \<equiv> "\<lambda>i. SOME x. x \<in> xs ! i"
  have xs_wf: "is_weak_ranking xs"
    by (simp add: xs_def weak_ranking_complete_preorder)
  hence f: "f i \<in> xs ! i" if "i < length xs" for i
    using that unfolding f_def is_weak_ranking_def
    by (intro someI_ex[of "\<lambda>x. x \<in> xs ! i"]) (auto simp: set_conv_nth)
  have f': "f i \<in> carrier" if "i < length xs" for i
    using that f weak_ranking_Union unfolding xs_def by (auto simp: set_conv_nth)
  def n \<equiv> "length xs - 1"
  from assms weak_ranking_Union have carrier_nonempty: "carrier \<noteq> {}" and "xs \<noteq> []" 
    by (auto simp: xs_def lotteries_on_def set_pmf_not_empty)
  hence n: "length xs = Suc n" and xs_nonempty: "xs \<noteq> []" by (auto simp add: n_def)
  have SD': "?pref p (f i) \<le> ?pref q (f i)" if "i < length xs" for i
    using f'[OF that] SD by (auto simp: SD_preorder preferred_alts_def)
  have f_le: "le (f i) (f j) \<longleftrightarrow> i \<ge> j" if "i < length xs" "j < length xs" for i j
    using that weak_ranking_index_unique[OF xs_wf that(1) _ f]
               weak_ranking_index_unique[OF xs_wf that(2) _ f]
    by (auto simp add: le intro: f elim!: of_weak_ranking.cases intro!: of_weak_ranking.intros)

  have "measure_pmf.expectation p u = 
          (\<Sum>i<n. (u (f i) - u (f (Suc i))) * ?pref p (f i)) + u (f n)"
    if p: "p \<in> lotteries_on carrier" for p
  proof -
    from p have "measure_pmf.expectation p u =
                   (\<Sum>i<length xs. u (f i) * measure_pmf.prob p (xs ! i))"
      by (simp add: f_def expected_utility_weak_ranking xs_def listsum_setsum_nth atLeast0LessThan)
    also have "\<dots> = (\<Sum>i<length xs. u (f i) * (?pref p (f i) - ?pref' p (f i)))"
    proof (intro setsum.cong HOL.refl)
      fix i assume i: "i \<in> {..<length xs}"
      have "?pref p (f i) - ?pref' p (f i) = 
              measure_pmf.prob p ({y. f i \<preceq>[le] y} - {y. f i \<prec>[le] y})"
        by (subst measure_pmf.finite_measure_Diff [symmetric])
           (auto simp: strongly_preferred_def)
      also have "{y. f i \<preceq>[le] y} - {y. f i \<prec>[le] y} = 
                   {y. f i \<preceq>[le] y \<and> y \<preceq>[le] f i}" (is "_ = ?A")
        by (auto simp: strongly_preferred_def)
      also have "\<dots> = xs ! i"
      proof safe
        fix x assume le: "le (f i) x" "le x (f i)"
        from i f show "x \<in> xs ! i" 
          by (intro weak_ranking_eqclass2[OF _ _ le]) (auto simp: xs_def)
      next
        fix x assume "x \<in> xs ! i"
        from weak_ranking_eqclass1[OF _ this f] weak_ranking_eqclass1[OF _ f this] i
          show "le x (f i)" "le (f i) x" by (simp_all add: xs_def)
      qed
      finally show "u (f i) * measure_pmf.prob p (xs ! i) =
                      u (f i) * (?pref p (f i) - ?pref' p (f i))" by simp
    qed
    also have "\<dots> = (\<Sum>i<length xs. u (f i) * ?pref p (f i)) - 
                      (\<Sum>i<length xs. u (f i) * ?pref' p (f i))"
      by (simp add: setsum_subtractf ring_distribs)
    also have "(\<Sum>i<length xs. u (f i) * ?pref p (f i)) = 
                 (\<Sum>i<n. u (f i) * ?pref p (f i)) + u (f n) * ?pref p (f n)" (is "_ = ?sum")
      by (simp add: n)
    also have "(\<Sum>i<length xs. u (f i) * ?pref' p (f i)) = 
                 (\<Sum>i<n. u (f (Suc i)) * ?pref' p (f (Suc i))) + u (f 0) * ?pref' p (f 0)"
      unfolding n setsum_lessThan_Suc_shift by simp
    also have "(\<Sum>i<n. u (f (Suc i)) * ?pref' p (f (Suc i))) = 
                 (\<Sum>i<n. u (f (Suc i)) * ?pref p (f i))"
    proof (intro setsum.cong HOL.refl)
      fix i assume i: "i \<in> {..<n}"
      have "f (Suc i) \<prec>[le] y \<longleftrightarrow> f i \<preceq>[le] y" for y
      proof (cases "y \<in> carrier")
        assume "y \<in> carrier"
        with weak_ranking_Union obtain j where j: "j < length xs" "y \<in> xs ! j"
          by (auto simp: set_conv_nth xs_def)
        with weak_ranking_eqclass1[OF _ f j(2)] weak_ranking_eqclass1[OF _ j(2) f]
          have iff: "le y z \<longleftrightarrow> le (f j) z" "le z y \<longleftrightarrow> le z (f j)" for z
          by (auto intro: trans simp: xs_def)
        thus ?thesis using i j unfolding n_def
          by (auto simp: iff f_le strongly_preferred_def)
      qed (insert not_outside, auto simp: strongly_preferred_def)
      thus "u (f (Suc i)) * ?pref' p (f (Suc i)) = u (f (Suc i)) * ?pref p (f i)" by simp
    qed
    also have "?sum - (\<dots> + u (f 0) * ?pref' p (f 0)) = 
      (\<Sum>i<n. (u (f i) - u (f (Suc i))) * ?pref p (f i)) -
       u (f 0) * ?pref' p (f 0) + u (f n) * ?pref p (f n)"
         by (simp add: ring_distribs setsum_subtractf)
    also have "{y. f 0 \<prec>[le] y} = {}"
      using hd_weak_ranking[of "f 0"] xs_nonempty f not_outside
      by (auto simp: hd_conv_nth xs_def strongly_preferred_def)
    also have "{y. le (f n) y} = carrier"
      using last_weak_ranking[of "f n"] xs_nonempty f not_outside
      by (auto simp: last_conv_nth xs_def n_def)
    also from p have "measure_pmf.prob p carrier = 1"
      by (subst measure_pmf.prob_eq_1)
         (auto simp: AE_measure_pmf_iff lotteries_on_def)
    finally show ?thesis by simp
  qed

  from assms[THEN this] show "measure_pmf.expectation p u \<le> measure_pmf.expectation q u"
    unfolding SD_preorder n_def using f'
    by (auto intro!: setsum_mono mult_left_mono SD' simp: utility_le_iff f_le)
  
next
  assume "\<forall>u. is_vnm_utility u \<longrightarrow> measure_pmf.expectation p u \<le> measure_pmf.expectation q u"
  hence expected_utility_le: "measure_pmf.expectation p u \<le> measure_pmf.expectation q u"
    if "is_vnm_utility u" for u using that by blast
  def xs \<equiv> "weak_ranking le"
  have le: "le = of_weak_ranking xs" and [simp]: "is_weak_ranking xs"
    by (simp_all add: xs_def weak_ranking_complete_preorder)
  have carrier: "carrier = \<Union>set xs"
    by (simp add: xs_def weak_ranking_Union)
  from assms have carrier_nonempty: "carrier \<noteq> {}"
    by (auto simp: lotteries_on_def set_pmf_not_empty)

  {
    fix x assume x: "x \<in> carrier"
    let ?idx = "\<lambda>y. length xs - find_index (op \<in> y) xs"
    have preferred_subset_carrier: "{y. le x y} \<subseteq> carrier"
      using not_outside x by auto
    have "measure_pmf.prob p {y. le x y} / real (length xs) \<le>
             measure_pmf.prob q {y. le x y} / real (length xs)"
    proof (rule field_le_epsilon)
      fix \<epsilon> :: real assume \<epsilon>: "\<epsilon> > 0"
      def u \<equiv> "\<lambda>y. indicator {y. y \<succeq>[le] x} y + \<epsilon> * ?idx y"
      have is_utility: "is_vnm_utility u"
      proof (unfold_locales; safe?)
        fix y z assume yz: "y \<in> carrier" "z \<in> carrier" "le y z"
        hence "indicator {y. y \<succeq>[le] x} y \<le> (indicator {y. y \<succeq>[le] x} z :: real)"
          by (auto intro: trans simp: indicator_def split: if_splits)
        moreover from yz 
          have "?idx y \<le> ?idx z"
          by (simp_all add: le of_weak_ranking_altdef carrier)
        ultimately show "u y \<le> u z" unfolding u_def using \<epsilon>
          by (intro add_mono mult_left_mono) simp_all
      next
        fix y z assume yz: "y \<in> carrier" "z \<in> carrier" "u y \<le> u z"
        consider "le x y \<longleftrightarrow> le x z" | "le x y" "\<not>le x z" | "le y x" "le x z"
          using yz complete[of x y] complete[of x z] x by blast
        thus "le y z"
        proof cases
          assume "le x y \<longleftrightarrow> le x z"
          with \<epsilon> yz carrier show ?thesis unfolding u_def
            by (auto simp: indicator_def le of_weak_ranking_altdef le_diff_iff' find_index_le_size)
        next
          assume "le x y" "\<not>le x z"
          with yz have "\<epsilon> * ?idx y \<le> \<epsilon> * ?idx z" by (simp add: u_def)
          with \<epsilon> yz carrier show ?thesis
            by (auto simp: le of_weak_ranking_altdef le_diff_iff' find_index_le_size)
        qed (blast intro: trans)
      qed (insert \<epsilon>, simp_all add: u_def)

      have "(\<Sum>y|le x y. pmf p y) \<le>
              (\<Sum>y|le x y. pmf p y) + \<epsilon> * (\<Sum>y\<in>carrier. ?idx y * pmf p y)"
        using \<epsilon> by (auto intro!: mult_nonneg_nonneg setsum_nonneg pmf_nonneg)
      also from expected_utility_le is_utility have 
        "measure_pmf.expectation p u \<le> measure_pmf.expectation q u" .
      with assms 
        have "(\<Sum>a\<in>carrier. u a * pmf p a) \<le> (\<Sum>a\<in>carrier. u a * pmf q a)"
        by (subst (asm) (1 2) integral_measure_pmf[OF finite_carrier])
           (auto simp: lotteries_on_def set_pmf_eq)
      hence "(\<Sum>y|le x y. pmf p y) + \<epsilon> * (\<Sum>y\<in>carrier. ?idx y * pmf p y) \<le> 
               (\<Sum>y|le x y. pmf q y) + \<epsilon> * (\<Sum>y\<in>carrier. ?idx y * pmf q y)"
        using x preferred_subset_carrier unfolding u_def
        by (simp add: setsum.distrib finite_carrier algebra_simps Int_absorb1 setsum_right_distrib)
      also have "(\<Sum>y\<in>carrier. ?idx y * pmf q y) \<le> (\<Sum>y\<in>carrier. length xs * pmf q y)"
        by (intro setsum_mono mult_right_mono) (simp_all add: pmf_nonneg)
      also have "\<dots> = measure_pmf.expectation q (\<lambda>_. length xs)"
        using assms by (subst integral_measure_pmf[OF finite_carrier]) 
                       (auto simp: lotteries_on_def set_pmf_eq)
      also have "\<dots> = length xs" by simp
      also have "(\<Sum>y | le x y. pmf p y) = measure_pmf.prob p {y. le x y}"
        using finite_subset[OF preferred_subset_carrier finite_carrier]
        by (simp add: measure_measure_pmf_finite)
      also have "(\<Sum>y | le x y. pmf q y) = measure_pmf.prob q {y. le x y}"
        using finite_subset[OF preferred_subset_carrier finite_carrier]
        by (simp add: measure_measure_pmf_finite)
      finally show "measure_pmf.prob p {y. le x y} / length xs \<le> 
                      measure_pmf.prob q {y. le x y} / length xs + \<epsilon>"
        using \<epsilon> by (simp add: divide_simps)
    qed
    moreover from carrier_nonempty carrier have "xs \<noteq> []" by auto
    ultimately have "measure_pmf.prob p {y. le x y} \<le>
                       measure_pmf.prob q {y. le x y}"
      by (simp add: field_simps)
  }
  with assms show "p \<preceq>[SD(le)] q" unfolding SD_preorder preferred_alts_def by blast
qed

end

end