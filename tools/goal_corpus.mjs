// 其余两档备考目标的原创预置样张语料。
// 仅提供内容；词数、答案字母、定位引文与解析均由 build_goal_packs.mjs 自动合成。
// 约束：题目行 9 段用 | 分隔，字段内不得出现 |；每段须含 20–200 字符、以 .?! 结尾的完整句；
// 不使用 e.g. / Mr. / 省略号等易被误切分的缩写；正确项下标 0–3 分布开且 A/B/C/D 均出现。

export const corpus = {
  // =====================================================================
  // cet4：校园生活、日常科技、环境健康。句式直观，多考直接细节与词义指代。
  // =====================================================================
  cet4: {
    theme: '校园共享自习室与绿色骑行出行',
    date: '2026-11-06',
    articles: [
      {
        title: 'The Shared Study Room on Campus',
        paragraphs: [
          `Across many universities, a quiet room with a long table has become the most contested space on campus. Students call it the shared study room, and it is neither a classroom nor a library. During examination weeks, seats fill within minutes of the doors opening. Some arrive with laptops and notes, while others bring only a notebook and a pencil. It matters because it offers the uninterrupted silence that a crowded dormitory rarely provides.`,
          `Rules for the room are simple, yet they are surprisingly hard to enforce. A sign near the entrance asks everyone to keep voices low and avoid phone calls. Most students respect it, since they depend on the same quiet themselves. Problems begin when a group reviews a project together, and one conversation breaks the concentration of a dozen people.`,
          `The library staff have tried several solutions over the past two years. They added a booking system so that students could reserve a seat for a fixed period. It reduced early-morning queues, but it created complaints about empty reserved seats. A few students now suggest dividing the room into a silent zone and a discussion zone, with unclear results.`,
          `Beyond the rules, the room reveals how students actually study. Many prefer to work near strangers who are also working, a habit some describe as quiet company. The presence of others makes long hours of reading less lonely and less tiring. The shared effort, not the furniture, turns an ordinary space into a small community.`,
          `For new students, learning to use such spaces is part of settling into campus life. They discover that a good seat is less important than a steady routine. A shared study room teaches, in a modest way, how to live with strangers. That lesson may last longer than anything memorised during a single examination week.`,
        ],
        zh: [
          `在许多大学里，一间摆着长桌的安静房间，已经成了校园里最抢手的空间。学生们把它叫作共享自习室，它既不是教室，也不是图书馆。到了考试周，门一开，座位几分钟内就被坐满。有人带着笔记本电脑和打印好的笔记来，也有人只拿一个本子和一支笔。这间屋子之所以重要，是因为它能提供拥挤的宿舍很少给得了的东西，也就是不被打断的安静。`,
          `自习室的规则很简单，可执行起来却出人意料地难。入口旁的牌子请大家放低声音、不要打电话。多数学生都照做，因为他们自己也依赖这份安静来完成工作。麻烦往往从某个小组决定一起讨论项目、又忘了自己身在何处开始。一段对话就能顺着长桌蔓延开，打断十几个人的思路。`,
          `过去两年里，图书馆的老师试过好几种办法。他们加了一套预约系统，让学生可以固定时段订一个座位。系统缓解了清晨排队，却又引出另一种抱怨：有些订了的座位一直空着。现在有学生建议把房间分成静音区和讨论区。这能不能让所有人满意还不好说，因为安静很难衡量，却很容易被看重。`,
          `规则之外，这间屋子还透露了学生实际是怎么学习的。很多人喜欢坐在同样在用功的陌生人旁边，有人把这叫作安静的陪伴。他人在场，似乎让长时间的阅读没那么孤单，也没那么累。一间只摆了桌子的房间，本身造不出这种效果。把普通空间变成一个小共同体的，是那份一起用力的氛围，而不是家具。`,
          `对新生来说，学会使用这样的空间，也是适应校园生活的一部分。他们会发现，一个好座位其实不如一份稳定的作息重要。他们也会学着在自己的需要和周围人的舒适之间找平衡。一间共享自习室，用很朴素的方式教人怎样与陌生人相处。这一课，可能比某个考试周里硬背下来的东西留得更久。`,
        ],
        q: [
          `细节题|Why does the shared study room matter to students?|It provides silence that a crowded dormitory rarely offers|It offers free laptops and printed notes to everyone|It is the only place used for examinations|It lets groups hold loud project discussions|0|1|把宿舍也能满足的条件错当成自习室独有的价值`,
          `细节题|What does the sign near the entrance ask students to do?|Reserve a seat through the booking system|Keep voices low and avoid phone calls|Bring only a notebook and a pencil|Divide the room into two separate zones|1|2|把后文才出现的管理措施误提前到入室须知`,
          `细节题|What problem did the booking system create?|It made the doors open much later|It led to complaints about empty reserved seats|It removed every repair stand on campus|It forced students to review projects together|1|3|把预约制的附带问题错记成开门时间的变化`,
          `词义题|What does the phrase "quiet company" refer to in Paragraph 4?|A rule that bans all conversation|A service offered by the library staff|The comfort of working near other focused students|A type of silent examination|2|4|把抽象比喻误解成一条具体的管理规定`,
          `主旨题|What lesson does the author draw in the final paragraph?|A good seat matters more than any routine|Examination weeks should be made shorter|Memorising facts is the main goal of study|Shared spaces quietly teach students how to live with strangers|3|5|把末段关于相处的感悟缩小成一条应试技巧`,
        ],
        lq: [
          `细节题|When do seats in the shared study room fill up fastest?|Right after the doors open during examination weeks|Late in the evening after the library closes|Only on weekends when no classes are held|Before the booking system was introduced|0|1|把考试周的高峰时段错记成闭馆前的冷清时段`,
          `推断题|What can be inferred about enforcing the room rules?|Rules are easy to enforce because everyone agrees|Most students keep quiet, yet a single group can disturb many|The staff have stopped trying to manage the room|Phone calls are welcome during examination weeks|1|2|把多数人守规与个别干扰并存的事实绝对化`,
          `细节题|What have the library staff added over the past two years?|More buses to the teaching building|A ban on all group projects|A booking system for reserving seats|Extra dormitories near the library|2|3|把预约系统错记成与交通或住宿有关的变化`,
          `细节题|According to Paragraph 4, what makes long reading hours less tiring?|Brighter furniture in the room|A strict rule about silence|Free coffee provided by the staff|The presence of other students who are also working|3|4|把他人相伴带来的心理作用错当成硬件条件`,
        ],
      },
      {
        title: 'Campus Cycling and Cleaner Air',
        paragraphs: [
          `On a mild morning, the bicycle racks outside the teaching building fill faster than the nearby bus stop. More students now ride to class instead of taking a crowded bus or driving a car. The change is small, yet it reflects a wider interest in daily habits and health. A short ride wakes the body, costs nothing and leaves no exhaust behind. For a campus built on flat ground, cycling is an obvious fit.`,
          `The university has supported the trend with practical changes rather than slogans. It widened several narrow paths and painted clear lanes between the dormitories and the libraries. Repair stands near the main gate let a student borrow a pump or fix a loose chain. Simple lighting along the paths made evening rides safer than before.`,
          `Health is not the only reason students give for choosing a bicycle. Many mention the chance to notice the season, the trees and the faces they pass each day. A bus ride hides the campus behind a window, while a bicycle keeps a person close to it. Riders also report arriving at class more alert and less impatient.`,
          `Still, cycling brings problems that a friendly poster cannot solve. Wet roads make sudden stops risky, and careless riding near crossings has caused minor accidents. Some students complain that broken bicycles sit chained to railings for months. The university now asks every rider to check brakes and tyres before the start of each term.`,
          `Taken together, these small choices add up to a noticeable difference in campus life. Fewer short car trips mean cleaner air around the teaching buildings and less noise at busy hours. A student who rides regularly gains gentle exercise without setting aside extra time for sport. Healthy routines, it seems, begin with a decision about how to travel a single kilometre.`,
        ],
        zh: [
          `天气温和的早晨，教学楼外的自行车架，比旁边的公交站满得还快。越来越多学生选择骑车上课，而不是挤公交或开车。这个变化本身不大，却反映出人们对日常习惯和健康的更广泛关注。短短一段骑行能让人清醒，不花钱，也不留下尾气。对一所建在地势平坦处的校园来说，骑车显然是顺理成章的选择。`,
          `学校没有喊口号，而是用一些实际改动来支持这股风气。它拓宽了几条窄路，在宿舍楼和图书馆之间画了清晰的车道。校门附近立起了维修架，学生可以在那儿借打气筒，或者紧一紧松掉的链条。沿路加了简单的照明之后，傍晚骑车也比从前更安心。这些措施花费不多，却消除了曾让人不愿骑车的那些小小顾虑。`,
          `健康并不是学生选择骑车的唯一理由。很多人提到，骑车让他们有机会注意到季节、树木，还有每天擦肩而过的面孔。坐公交时，校园被隔在车窗后面；骑车却让人始终离它很近。骑车的人也说，到教室时更清醒、不那么急躁。这点好处很难在一项研究里被证实，却在安静的早晨很容易被感觉到。`,
          `当然，骑车也带来一些友好海报解决不了的问题。路面湿滑时急刹有风险，路口附近骑得大意也造成过几起小事故。有学生抱怨，坏掉的自行车被锁在栏杆上几个月都没人管。维修架有帮助，但它替代不了定期保养的习惯。现在学校要求每位骑车人在每学期开始前检查刹车和轮胎。`,
          `这些细小的选择加在一起，让校园生活有了看得见的不同。短途开车少了，教学楼周围的空气更干净，繁忙时段的噪音也更小。经常骑车的人不必另外挤出时间运动，就得到了温和的锻炼。也许最持久的价值，是它提醒我们：健康的日常并不需要宏大的计划。它始于一个关于如何走完一公里的决定。`,
        ],
        q: [
          `细节题|Why is cycling described as an obvious fit for the campus?|The campus is built on flat ground and trips are short|The university banned all buses and cars last year|Every student already owns a new bicycle|The teaching buildings have no windows at all|0|1|把地势与短途的便利错当成强制禁令的结果`,
          `细节题|What did the university paint between the dormitories and libraries?|Large advertising posters|New parking spaces for cars|Clear bicycle lanes|White lines for a running track|2|2|把自行车道错记成与汽车或跑步相关的标线`,
          `推断题|What reason for cycling goes beyond physical health?|Riders save a great deal of money on fuel|Riders notice the trees, the season and the people they pass|Riders no longer need to attend morning classes|Riders can avoid all traffic rules on campus|1|3|把骑行带来的观察与亲近感偷换成省钱的算计`,
          `细节题|What does the university ask riders to do before each term?|Buy a brand new bicycle|Register for a bus pass|Paint their own lane markings|Check brakes and tyres|3|4|把学期前的车况检查错当成购买或登记手续`,
          `主旨题|What is the main point of the final paragraph?|Grand plans are the only way to build healthy routines|Small daily choices can improve air, noise and personal health|Cycling should replace every form of exercise|Car trips are the single cause of campus noise|1|5|把末段关于小习惯的论点夸大成唯一手段`,
        ],
        lq: [
          `细节题|What do the bicycle racks fill faster than on a mild morning?|The nearby bus stop|The university library|The examination hall|The repair stand queue|0|1|把比较对象从公交站偷换成校内其他设施`,
          `细节题|What can a student borrow at the repair stands near the main gate?|A free bus ticket|A new helmet every term|A pump or tools to fix a loose chain|A map of the examination rooms|2|2|把维修工具错记成票务或考试用品`,
          `细节题|What problem do wet roads create for riders?|They make the lanes much wider|They make sudden stops risky|They close every repair stand|They increase the number of bus passengers|1|3|把天气带来的安全隐患错当成设施变化`,
          `推断题|What does the author suggest about healthy routines?|They require expensive equipment and strict plans|They matter only during examination weeks|They are impossible on a crowded campus|They can begin with a small everyday decision|3|5|把日常小决定能开启习惯的观点颠倒成高门槛要求`,
        ],
      },
    ],
    translation: {
      chinese: `每到学期末，校园图书馆都会办一次旧书交换。同学们把读过的小说和笔记带到一楼大厅，摆在长桌上。任何人都可以免费取走需要的书，留下不再用的书。活动起初只是几个学生的提议，如今已成每学期的传统。它让旧书重新流通，也让陌生同学因为一本书聊起天来。有人在书页里发现前一位读者的批注，像收到一封陌生人的短信。组织者说，交换的不是书，而是一段可以继续的阅读。`,
      hints: ['second-hand book exchange', 'lay them out on long tables', 'for free', 'keep old books in circulation', 'notes left in the margins'],
      reference: `At the end of every term, the campus library holds a second-hand book exchange. Students bring finished novels and notes to the hall on the first floor and lay them out on long tables. Anyone may take a book they need for free, or leave one they no longer use. What began as a suggestion from a few students has become one of the most anticipated traditions of the term. It keeps old books in circulation, cuts waste, and starts conversations between strangers. Some readers find notes in the margins, like a short letter from someone they have never met. The organisers say that what is exchanged is not a book but a reading journey that can continue.`,
      scoringPoints: [
        ['学期末举办的旧书交换', 'a second-hand book exchange held at the end of every term'],
        ['把读过的书摆在一楼长桌上', 'lay finished books out on long tables on the first floor'],
        ['免费取走或留下不再用的书', 'take a needed book for free or leave an unused one'],
        ['减少浪费并让旧书重新流通', 'cut waste and keep old books in circulation'],
        ['书页批注像陌生人的短信', 'notes in the margins are like a letter from a stranger'],
        ['交换的是可继续的阅读', 'what is exchanged is a reading journey that can continue'],
      ],
      highlights: ['What began as ... has become ...', 'keep ... in circulation', 'not only ... but also ...', 'like a short letter from someone ...', 'what is exchanged is not ... but ...'],
    },
    writing: {
      topic: 'The Habit of Keeping a Weekly Plan',
      prompt: 'Directions: For this part, you are allowed 30 minutes to write an essay on the habit of keeping a weekly plan. You should write at least 120 words but no more than 160 words.',
      requirements: ['120–160 words', '30 minutes', '3 paragraphs: thesis → flexible planning → understanding time'],
      outlineHints: [
        '开头：学期常在希望与困惑之间溜走，一张写下来的每周清单就够用。',
        '中间：排满会脆弱，只锁定两三件要事，留弹性，周末温和复盘。',
        '结尾：计划是理解时间，划掉与重复处透露真正重心，换来从容。',
      ],
      modelEssay: [
        `Many students start a term hopefully and end it wondering where the weeks went. A simple weekly plan helps. It need not be detailed, only written down and consulted often. It turns vague intentions into a short list of doable tasks.`,
        `A good plan leaves room for surprise. If every hour is filled, one late assignment can break the schedule. Wise students mark only the tasks that matter most and keep the rest flexible. A Sunday review reveals more than any Monday resolution.`,
        `Keeping a weekly plan is less about controlling time than understanding it. Over a term, the crossed-out lines show what a person values. A notebook like this costs almost nothing, yet it changes how a student meets a busy week. The calm it brings rewards a small effort.`,
      ],
      structure: [
        '第一段：提出每周计划能把模糊打算变成可执行的短清单，无需精美。',
        '第二段：好计划要留余地，只标最重要的两三件事，并在周末复盘而非自责。',
        '第三段：计划的意义在于理解时间而非控制时间，划掉与重复的任务透露真正的重心。',
      ],
      expressions: ['turn vague intentions into a short list', 'a sense of failure', 'mark only the tasks that matter most', 'keep the rest flexible', 'review the plan at the end of the week', 'meet a busy week'],
      translation: [
        `许多学生开学时满怀希望，期末却疑惑几周时间去了哪里。一份简单的每周计划就能带来不同。它不必写得详细或漂亮，只需要写下来、常常翻看。它的意义是把模糊的打算变成一张确实能完成的短清单。`,
        `好的计划会给意外留余地。如果每个小时都被排满，一次迟交的作业或一个疲惫的夜晚就足以打乱整张表，带来挫败感。因此聪明的学生只标出最重要的两三件事，其余保持弹性。他们也会在周末回看计划，不是为了责备自己，而是留意哪些事总被往后推。这个小习惯，比周一早晨立下的任何决心都更能透露真正的优先级。`,
        `坚持每周计划，与其说是控制时间，不如说是理解时间。一学期下来，被划掉的条目和反复出现的任务，会悄悄显示一个人看重什么、一天究竟花在了哪里。这样的本子几乎不花什么钱，却能改变学生面对忙碌一周的方式。它带来的从容，是对一点点努力很实在的回报。`,
      ],
    },
  },

  // =====================================================================
  // kaoyan：科技伦理、公共政策、劳动经济。长句与让步转折，重推断/态度/主旨，
  // 干扰项在范围、程度、因果上作细微变化。
  // =====================================================================
  kaoyan: {
    theme: '算法判断的归属与成人再培训政策',
    date: '2026-11-06',
    articles: [
      {
        title: 'The Quiet Transfer of Judgement',
        paragraphs: [
          `Few organisational changes are as quietly consequential as the decision to let software rank, filter and recommend on behalf of human beings. Such systems promise consistency, speed and freedom from the fatigue that clouds judgement late in a working day. Yet every criterion they apply was chosen by someone, and that choice rarely appears in the interface shown to the person being judged. What presents itself as neutral arithmetic is, on inspection, a set of prior decisions frozen into code. The convenience of the tool should not be confused with the absence of a decision-maker.`,
          `Defenders of automation are right to note that human discretion is hardly a benchmark of fairness. Interviewers favour candidates who resemble them, and tired reviewers drift toward whichever option requires the least effort. A well-designed rule, applied uniformly, can restrain these impulses rather than amplify them. The trouble is that the comparison is usually drawn against an idealised human, not against the actual, hurried and biased alternative. Once the baseline is stated honestly, the case for automation becomes an argument about which errors we prefer, not about whether errors exist.`,
          `The deeper difficulty concerns explanation rather than accuracy alone. A person refused a loan, a shift or a place on a shortlist is often told only that a threshold was not met. Because the model weighs dozens of features at once, even its designers may struggle to say which consideration proved decisive. This opacity shifts the burden of proof onto the individual, who must now guess at a logic nobody will fully articulate. A procedure that cannot give reasons can hardly be called accountable, however carefully its outputs are audited.`,
          `Some institutions have responded by requiring a human to confirm every automated recommendation. In practice, this safeguard often decays into a ritual, since a reviewer facing a confident score and a long queue has little incentive to disagree. The signature that was meant to restore responsibility can instead distribute it until no one clearly owns the outcome. Genuine oversight would demand time, training and the authority to overturn a result without penalty, all of which cost more than a nominal approval step. Whether organisations are willing to pay that price remains an open question.`,
          `None of this warrants a blanket rejection of automated tools, which already spare people from tedious and error-prone work. The more defensible position is to treat judgement as something that must be continually justified rather than merely delegated. Systems should be designed so that their criteria can be inspected, contested and revised when they produce patterns nobody intended. The question is not whether machines may advise us, but whether we keep the capacity to answer for what we accept. A society that forgets this distinction may gain efficiency while quietly losing the habit of giving reasons.`,
        ],
        zh: [
          `很少有哪种组织变革，像「让软件替人去排序、筛选和推荐」这个决定那样，安静却影响深远。这类系统许诺的是一致、迅速，以及摆脱工作日晚些时候拖累判断的疲惫。然而它们所套用的每一条标准，都是某个人选出来的，而这个选择很少出现在被评判者所看到的界面上。看上去像是中立算术的东西，细看之下，其实是一组被冻结进代码里的事先决定。工具的便利，不该被误认为决策者的缺席。`,
          `为自动化辩护的人说得没错：人的自由裁量本来就算不上公平的标杆。面试官偏爱与自己相似的候选人，疲惫的评审则容易滑向最省力的那个选项。一条设计良好、一视同仁的规则，能够约束这些冲动，而不是放大它们。问题在于，这种比较通常是对着一个理想化的人做的，而不是对着现实里匆忙又带偏见的替代方案。一旦把基准诚实地说清楚，支持自动化的理由就变成了「我们更愿意容忍哪一类错误」，而不是「错误是否存在」。`,
          `更深的难题在于解释，而不只是准确。一个被拒了贷款、班次或短名单名额的人，往往只被告知某项阈值没有达到。由于模型同时权衡几十个特征，就连设计者也未必说得出究竟哪一项起了决定作用。这种不透明把举证的责任推给了个人，他如今得去猜一套没人愿意完整讲清的逻辑。一个给不出理由的程序，无论其输出被审计得多仔细，都很难称得上可问责。`,
          `有些机构的应对办法，是要求由人来确认每一条自动推荐。实践中，这道防线常常退化成走过场：面对一个自信的分数和排得长长的队列，复核者几乎没有动力提出异议。本想找回责任的那一个签名，反而把责任摊薄到没人清楚承担结果。真正的监督需要时间、培训，以及能够无惩罚地推翻结论的权限，而这些都比一次名义上的点击贵得多。机构是否愿意付这笔代价，仍是一个悬而未决的问题。`,
          `这一切都不构成对自动化工具的全盘否定，它们早就把人从枯燥易错的工作里解放出来。更站得住脚的立场，是把判断看成一件必须不断被说明理由、而不能仅仅被交出去的事。系统的设计应当让其标准可以被检视、被质疑，并在产生无人预料的结果时被修订。问题不是机器可不可以给我们建议，而是我们是否保留了为自己所接受的东西作答的能力。一个忘记这条分别的社会，或许得到了效率，却悄悄丢掉了讲理由的习惯。`,
        ],
        q: [
          `推断题|What does the author imply about the claim that automated systems are neutral?|The claim is false because every applied criterion reflects an earlier human choice|The claim holds only when the software is open source|The claim is supported by the speed of modern processors|The claim applies mainly to small organisations|0|1|把界面呈现的中立表象误当成没有人为取舍`,
          `态度题|How does the author characterise the defenders' comparison with human judgement?|As conclusive proof that machines are fairer|As reasonable in principle but misleading because it uses an idealised baseline|As irrelevant to any discussion of fairness|As evidence that all human reviewers should be replaced|1|2|把有保留的肯定夸大成对自动化无条件的辩护`,
          `细节题|Why is it difficult to explain an automated decision to an affected person?|The relevant law expressly forbids giving reasons|Affected people rarely ask for an explanation|The model weighs many features at once, so even designers may not know which mattered|The software deletes its records immediately after each case|2|3|把技术上的不可解释性错记成法律或记录问题`,
          `推断题|What does the author suggest about a human confirmation step?|It fully restores accountability at almost no cost|It is required by international standards everywhere|It eliminates the need to audit outputs|It often becomes a ritual unless reviewers have time, training and real authority|3|4|把名义上的签字误认为已经实现实质问责`,
          `主旨题|Which statement best captures the author's overall position?|Automated tools should be banned from all consequential decisions|Automated tools are useful, but the duty to justify judgements must not be delegated|Human reviewers are always more accurate than any model|Efficiency is the only standard by which systems should be judged|1|5|把有条件保留的立场偷换成全面否定或唯一标准`,
        ],
        lq: [
          `细节题|What do automated systems promise according to Paragraph 1?|Consistency, speed and freedom from fatigue|Complete freedom from all legal oversight|A guarantee of higher profits every year|The removal of every human criterion|0|1|把工具带来的效率承诺扩大成全面免责`,
          `推断题|Why can a uniform rule be defended in Paragraph 2?|Because it removes the need for any reviewer|Because it can restrain the biased impulses of hurried human reviewers|Because it is always based on perfect data|Because it makes every decision faster than thought|1|2|把一致规则能抑制偏见的有限好处夸大成无需复核`,
          `词义题|What does "opacity" in Paragraph 3 most nearly mean?|The speed of a calculation|The accuracy of a threshold|The lack of a clear, articulable reason|The cost of hiring designers|2|3|把不可解释理解成运算速度或成本问题`,
          `态度题|What is the author's view on paying for genuine oversight?|It is unnecessary because nominal approval is enough|It is a settled cost that every organisation already accepts|It would ban automated advice entirely|It remains uncertain whether organisations will bear that cost|3|4|把开放未决的问题说成已解决的既定事实`,
        ],
      },
      {
        title: 'Why Cities Pay Adults to Retrain',
        paragraphs: [
          `When a large employer closes a plant, the loss is rarely confined to the workers who receive notice. Local shops lose customers, councils lose tax revenue, and the skills that once held a town together begin to scatter. Governments have therefore grown interested in subsidising adult retraining, not as charity but as a form of economic maintenance. The logic is deceptively simple: if displaced workers can be moved into expanding sectors, the shock need not become permanent decline. Whether the premise holds in practice is a far harder question than the slogan suggests.`,
          `Early programmes were designed around the assumption that a short course could translate directly into a new job. Evaluations soon complicated that optimism. Participants who completed training did gain credentials, yet their wages often rose only modestly, and many returned to work in fields unrelated to what they had studied. The problem was not laziness or poor teaching alone, but a mismatch between the courses on offer and the vacancies that actually existed nearby. A certificate, it turned out, is not the same thing as a labour market.`,
          `Policymakers drew two different lessons from these results. Some concluded that the answer was tighter targeting, with curricula written alongside local employers and updated as demand shifted. Others argued that the deeper failure lay upstream, in regional economies too thin to absorb skilled workers no matter how well they were trained. Both readings can be true at once, which is precisely what makes evaluation so contentious. A programme that looks ineffective in a shrinking town may be succeeding at something harder to measure, namely keeping people attached to work at all.`,
          `Funding rules add another layer of difficulty, since they reward what can be counted quickly. Completion rates and immediate placements are easy to audit, while confidence, mobility and the avoidance of long-term unemployment are not. Agencies responding to such incentives have reason to select candidates already close to employment, a practice that improves statistics while leaving the most disadvantaged untouched. This is not necessarily bad faith; it is the predictable behaviour of institutions judged by narrow indicators. The measure, in effect, begins to shape the thing it was meant merely to observe.`,
          `A more honest settlement would treat retraining as one instrument among several, alongside housing, transport and direct support for creation of jobs. It would also admit that some transitions take years and that a single course cannot carry that weight. None of this diminishes the case for helping adults adapt, which remains stronger than the case for doing nothing. It does, however, argue against promising a quick conversion of decline into growth. Public patience, more than any particular curriculum, may be the scarcest resource such policies require.`,
        ],
        zh: [
          `当一家大雇主关掉工厂，损失很少只落在收到通知的工人身上。本地店铺少了顾客，地方议会少了税收，曾经把一座小镇拢在一起的技能也开始四散。因此，政府越来越愿意补贴成人再培训，不是当作慈善，而是当作一种经济维护。逻辑简单得有些迷惑：只要能把失业的工人送进扩张中的行业，冲击就不必变成长期的衰败。这个前提在实践中是否成立，远比口号所说的要难回答得多。`,
          `早期的项目建立在一个假定之上：一门短期课程就能直接换成一份新工作。评估很快让这种乐观变得复杂。完成培训的人确实拿到了证书，可工资往往只涨了一点，许多人最后回到与所学毫无关系的行业里干活。问题不只是懒散或教得不好，而是开设的课程与附近真实存在的岗位之间对不上。一张证书，原来并不等于一个劳动力市场。`,
          `政策制定者从这些结果里读出了两种不同的教训。一些人认为答案是更精准的定位：课程该与本地雇主一起写，并随需求变化而更新。另一些人则说，更深的失败在上游，在于区域经济太单薄，无论工人训练得多好都吸纳不了。两种解读可以同时成立，而这恰恰让评估变得争议不断。一个在萎缩小镇里看似无效的项目，可能正在做成一件更难衡量的事，也就是让人们始终没有脱离工作。`,
          `资金规则又添了一层难处，因为它们奖励的是能被迅速计数的东西。结业率和即时上岗容易审计，而信心、流动能力，以及避免长期失业，却不容易。面对这类激励的机构，有理由挑那些本来就离就业很近的人，这种做法改善了统计数字，却把最弱势的人留在原处。这未必是恶意，而是被狭窄指标评判的机构可预料的行为。指标实际上开始塑造它本想只是观察的那件事。`,
          `更诚实的安排，会把再培训当作若干工具之一，与住房、交通，以及直接扶持创造岗位并列。它也会承认，有些转型要花上好几年，一门课程扛不起这个重量。这些都不削弱帮助成年人适应变化的理由，它仍然比什么都不做更强。不过，它确实提醒我们：别轻易许诺把衰败迅速转成增长。比起任何一套具体课程，公共耐心或许才是这类政策最稀缺的资源。`,
        ],
        q: [
          `推断题|Why do governments subsidise adult retraining according to Paragraph 1?|Mainly to reduce the workload of local councils|To treat it as economic maintenance rather than charity|To guarantee that every closed plant will reopen|To replace all existing schools in a region|1|1|把经济维护的动机错记成慈善或学校替代`,
          `细节题|What did early evaluations reveal about training programmes?|Wages rose sharply for every participant|No participant ever found work again|Credentials were gained but wage gains were modest and jobs often unrelated|Courses were always taught by local employers|2|2|把有限且错位的收益夸大成普遍大幅涨薪`,
          `推断题|What does the author say about the two lessons policymakers drew?|Both can be true at once, which makes evaluation contentious|One has been proven false by later data|They both call for ending all subsidies|They apply only to expanding sectors|0|3|把两种并行成立的解读说成非此即彼的对错`,
          `推断题|Why might agencies select candidates already close to employment?|Because the law excludes the long-term unemployed|Because such candidates refuse any training|Because employers forbid other applicants|Because narrow indicators reward easily audited outcomes|3|4|把指标激励下的选择行为错当成法律或禁令所致`,
          `主旨题|Which best summarises the author's conclusion?|Retraining is useless and should be abandoned|Retraining helps, but it needs patience and complementary policies rather than quick promises|Housing and transport alone can solve every decline|A single course is sufficient for any transition|1|5|把有条件肯定的结论偷换成全盘否定或单一手段`,
        ],
        lq: [
          `细节题|What happens to a town when a large employer closes a plant?|Local shops lose customers and councils lose tax revenue|Only the workers who receive notice are affected|Every resident immediately finds a better job|The local skills become more valuable at once|0|1|把连锁的地方损失缩小成仅通知员工受影响`,
          `细节题|What mismatch did evaluators identify in Paragraph 2?|Between the length of courses and the age of participants|Between teacher salaries and student fees|Between course content and the vacancies that existed nearby|Between national targets and foreign standards|2|2|把课程与岗位错配偷换成课时与年龄的关系`,
          `推断题|What is said about a programme in a shrinking town?|It is definitely wasting public money|It always produces immediate wage growth|It should be audited only on completion rates|It may succeed at keeping people attached to work, which is hard to measure|3|3|把难以衡量的隐性成效误判为确定无效`,
          `态度题|What does the author identify as the scarcest resource for such policies?|A particular curriculum design|Public patience over long transitions|Larger training budgets alone|Stricter completion audits|1|5|把长期耐心这一稀缺资源错认成课程或预算`,
        ],
      },
    ],
    translation: {
      chinese: `近年来，越来越多的博物馆把馆藏文物制成高清数字影像，向公众免费开放。支持者认为，这打破了地域与开放时间的限制，让偏远地区的研究者和观众都能近距离观察纹饰与铭文。它也降低了反复提取易损原件的风险。然而，数字化并不等于原作。屏幕均匀的光线会抹去器物表面的细微起伏，观看者很难体会尺度与材质的感受。一些馆长提醒，数字资源应被看作邀请而非替代：它把人引向展厅，而不是让人不再走进展厅。如何在开放获取与实物保护之间取得平衡，仍是各馆讨论的议题。`,
      hints: ['high-resolution digital images', 'open to the public free of charge', 'remove the limits of geography', 'handle fragile originals', 'an invitation rather than a replacement'],
      reference: `In recent years, a growing number of museums have produced high-resolution digital images of their collections and opened them to the public free of charge. Supporters argue that this removes the limits of geography and opening hours, allowing researchers in remote regions and ordinary visitors alike to examine decorative patterns and inscriptions at close range. It also reduces the risk of repeatedly handling fragile originals. Yet digitisation is not the same as the object itself. The even light of a screen erases subtle surface unevenness, and viewers can hardly recover the sense of scale and material that a physical encounter provides. Some directors therefore caution that digital resources should be an invitation rather than a replacement: they lead people toward the gallery instead of making it unnecessary. Striking a balance between open access and the care of originals remains a question institutions continue to debate.`,
      scoringPoints: [
        ['把馆藏制成高清影像并免费开放', 'produce high-resolution digital images and open them free of charge'],
        ['打破地域与开放时间的限制', 'remove the limits of geography and opening hours'],
        ['近距离观察纹饰与铭文', 'examine decorative patterns and inscriptions at close range'],
        ['降低反复提取易损原件的风险', 'reduce the risk of repeatedly handling fragile originals'],
        ['屏幕光线抹去表面起伏', 'the even light of a screen erases subtle unevenness'],
        ['数字资源是邀请而非替代', 'digital resources are an invitation rather than a replacement'],
      ],
      highlights: ['a growing number of ...', 'remove the limits of ...', 'leaving more room for ...', 'is not the same as ...', 'should be treated as an invitation rather than a replacement', 'Striking a balance between ... and ... remains ...'],
    },
    writing: {
      topic: 'The Limits of Measurable Outcomes',
      prompt: 'Directions: For this part, you are allowed 30 minutes to write an essay on the limits of measurable outcomes in public institutions. You should write at least 160 words but no more than 200 words.',
      requirements: ['160–200 words', '30 minutes', '3 paragraphs: thesis → the temporal problem → indicators as signals'],
      outlineHints: [
        '开头：指标有治理价值，但清晰导致狭窄，快速可计数的事挤走缓慢重要的事。',
        '中间：重要效果成熟慢、难归因；回应测量派的合理担忧，提出第三条路。',
        '结尾：指标是信号不是判决，配慢判断并肯修订，守住报表与初衷之别。',
      ],
      modelEssay: [
        `Modern institutions are fond of numbers, and for good reason. A clear indicator can reveal waste and make an organisation answerable. Yet the clarity that makes a measure useful also makes it dangerously narrow. Whatever can be counted quickly tends to displace whatever matters slowly, and agencies learn to serve the number rather than the person in front of it.`,
        `The deeper problem is temporal. The effects institutions value, such as confidence or persistence, mature over years and resist neat attribution. Defenders of measurement reply that vague goals invite favouritism, and without a common standard decisions drift toward habit and connection. The choice is not between measurement and chaos, but between a single loud indicator and an imperfect bundle of evidence that keeps several kinds of value in view.`,
        `A wiser practice would treat indicators as signals rather than verdicts, pairing numbers with sustained observation. This is untidy and will never satisfy a demand for one ranking. It may, however, keep institutions honest about the difference between what they can report and what they hope to achieve. A society that forgets that distinction risks becoming very good at things it never intended to value.`,
      ],
      structure: [
        '第一段：指标有治理价值，但可快速计数的事会挤走缓慢重要的事；扭曲源于激励而非欺骗。',
        '第二段：真正重要的效果成熟慢、难归因；测量与混乱之间还有一束不完美证据的第三条路。',
        '第三段：把指标当信号而非判决，配合慢判断并随时修订，守住报表与初衷之间的差别。',
      ],
      expressions: ['for good reason', 'serve the number rather than the person', 'resist neat attribution', 'drift toward habit and connection', 'a deliberately imperfect bundle of evidence', 'treat indicators as signals rather than verdicts', 'what they can report and what they actually hope to achieve'],
      translation: [
        `现代机构偏爱数字，而且不无道理。一个清晰的指标能暴露浪费、比较方案，让庞大组织对公众有所交代。然而，正是让指标有用的那种清晰，也使它危险地狭窄。凡能被迅速计数的事，往往会挤走那些缓慢才显出分量的问题。只以就业率评判的机构、只看分数的学校、只算接诊量的诊所，都会慢慢学会服务数字，而不是眼前的人。这种扭曲很少源于不诚实，它更像是有能力的人面对既有激励时的正常反应。`,
        `更深的难处在于时间。机构真正看重的效果，比如自信、好奇心，或者愿意回到难题上的习惯，往往要多年才成熟，也难以干脆地归因。季度报告看不见它们，于是理性的管理者没什么理由去保护它们。为测量辩护的人会说，模糊的目标会纵容偏袒与惰性，这一反驳值得认真对待。若完全没有共同标准，决策就会滑向惯例与人情。因此，选择并不是在测量与混乱之间二选一，而是在一个响亮的单一指标，与一束刻意不完美、却让多种价值同时可见的证据之间取舍。`,
        `更明智的做法，是把指标当作信号而非判决。数字应当配上更缓慢的判断方式：持续的观察、当事人的陈述，以及在指标开始失真时愿意修改它的气度。这不整齐，也费钱，而且永远满足不了人们想要一张排行榜的期待。但它或许能让机构诚实地守住一条界线：能写进报表的，与真正希望达成的，并不相同。一个忘记这条界线的社会，有可能变得非常擅长那些它本来并不打算珍视的事。`,
      ],
    },
  },
};
