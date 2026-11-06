// 四档备考目标的原创预置样张语料。
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

  // =====================================================================
  // tem4：语言学习、校园成长、文化生活、阅读与媒体。叙述与说明并重，
  // 含语气/修辞题。
  // =====================================================================
  tem4: {
    theme: '语言学习笔记与校园纸刊阅读',
    date: '2026-11-06',
    articles: [
      {
        title: 'Learning a Language by Keeping a Notebook',
        paragraphs: [
          `When I joined the exchange programme, I carried a notebook and a fear that others spoke faster than I could listen. Classes were lively, but I often lost the thread before I could form a reply. A teacher noticed my silence and told me to write down one phrase each day, not rules but a sentence someone really said. I began that evening with a question a neighbour had asked at the bus stop.`,
          `The habit changed what I paid attention to. Instead of chasing every unknown word, I started listening for complete turns of phrase that I could borrow later. A greeting, an apology, a way of softening a disagreement all became small, portable things. Copying them by hand slowed me down enough to notice their shape, and the notebook filled with ordinary language no textbook had bothered to include.`,
          `Looking back, the notebook worked because it turned a vague anxiety into a manageable task. Fluency had seemed like a distant country I would never reach, while a single phrase was something I could collect before dinner. The entries recorded my mistakes without scolding me, since a misheard word could be corrected the next day with a laugh. My classmates who kept neat grammar charts sometimes progressed faster on tests, yet I grew more willing to speak.`,
          `There is a wider lesson here about how we judge progress in any skill. Measurable milestones are comforting, but they rarely capture the moment when a strange sound becomes familiar. A learner who records what was once confusing keeps a private map of that change. Teachers are right that a notebook alone will not build a vocabulary, yet used alongside regular practice it gives memory something concrete to hold.`,
          `I still have the notebook, its cover softened by years in a pocket. The early pages are full of careful, awkward sentences that I would now write differently. I keep them because they show a person who did not yet know the language but kept turning up to meet it. Collect one real sentence a day, and let the pile quietly argue that you are moving, even on the days when it feels otherwise.`,
        ],
        zh: [
          `刚参加交换项目时，我随身带着一个小本子，还有一份不愿说出口的担心：别人说得都比我听得快。课堂很热闹，可我常常还没想好怎么回答，一段对话的线索就已经断了。一位老师注意到我的沉默，给了一个听起来朴素得几乎没用的建议。她说，每天记下一句话，不是记一串规则，而是记某个真的对你说过的一句话。那天晚上我就开始了，写的是在车站一位邻居问我的问题。`,
          `这个习惯改变了我留意的东西。我不再追着每一个生词跑，而是开始听那些以后能借来用的完整说法。一句问候、一句道歉、一种把分歧说得委婉的方式，都成了可以随身带走的小东西。手写抄下来让我慢到足以看清它们的形状，本子也慢慢填满那些教科书懒得收进去的日常语言。几个月后重读那几页，我能想起每条句子连着的街道、天气和那张脸。`,
          `现在回头看，我觉得本子管用，是因为它把一种含糊的焦虑变成了能应付的小任务。流利曾像一座我永远到不了的远方，而一句话是我晚饭前就能收进来的东西。那些记录也记下了我的错，却并不责备我：一个听岔的词写下来，第二天可以笑着改过来。班里把语法表整理得整整齐齐的同学，有时在考试上进步更快，我却变得更敢开口。我发现，信心是由许多细小的证据堆起来的。`,
          `这里还有一层关于「怎样衡量任何一项技能的进步」的更大道理。可量化的里程碑让人安心，却很少捕捉到一个陌生声音忽然变熟的那一刻。一个把曾经困惑的东西记下来的人，手里就留着一张关于这种变化的私人地图。老师有时嫌这样的收集不成体系，他们说光靠本子建不起词汇量，这没错。但把它和日常练习放在一起用，它给了记忆一点抓得住的东西，这比卷面上的一个分数能做的更多。`,
          `那个本子我至今还留着，封皮因为常年揣在口袋里已经软了。前面几页写满小心而笨拙的句子，如今我会换一种写法。我偏留着它们，正因为它们显出一个人：那时还不懂这门语言，却仍一次次去见它。任何刚开始做一件难事的人，都可以试试这个很小的办法。每天收一句真实的话，让那一摞纸安静地替你证明：即便在觉得原地不动的日子里，你其实一直在往前。`,
        ],
        q: [
          `细节题|What did the teacher advise the writer to do each day?|Memorise a list of grammar rules|Write down one phrase someone actually said|Record every unknown word in a dictionary|Practise speaking faster than classmates|1|1|把记一句真实话语的建议错当成整理语法规则`,
          `细节题|What did the writer begin to listen for instead of every unknown word?|Complete turns of phrase that could be borrowed later|Long lists of irregular verbs|The teacher's corrections only|Recordings played at double speed|0|2|把关注完整短语偷换成只听生词或纠错`,
          `推断题|Why did the notebook help reduce the writer's anxiety?|It replaced all classroom lessons|It proved the writer was better than classmates|It removed the need to speak at all|It turned a distant goal into a small daily task|3|3|把化整为零的作用夸大成替代课程或免开口`,
          `语气题|What tone does the writer use when describing the early notebook pages?|Bitter regret about wasted years|Affectionate acceptance of earlier awkwardness|Cold detachment from private records|Open mockery of former classmates|1|5|把温和回望的语气误读成懊悔或嘲讽`,
          `修辞题|What is the effect of the phrase "let the pile quietly argue"?|It suggests the notebook should be thrown away|It compares learning to a loud public debate|It turns collected sentences into a gentle proof of progress|It introduces a formal statistical method|2|5|把累积手稿拟人化为温和证据误读成丢弃或统计`,
        ],
        lq: [
          `细节题|Where did the writer hear the first sentence copied into the notebook?|At a bus stop, from a neighbour|In a crowded lecture hall|During a grammar examination|From a recorded radio programme|0|1|把车站邻人的问话错置成课堂或考试内容`,
          `细节题|What did copying phrases by hand allow the writer to notice?|The price of the notebook|The number of pages left blank|The teacher's handwriting style|The exact shape and rhythm of the expressions|3|2|把抄写带来的细察误记成对物品或字迹的留意`,
          `推断题|How did the notebook treat the writer's mistakes?|It erased them at once|It ranked them by seriousness|It recorded them without scolding so they could be corrected later|It sent them to the teacher each week|2|3|把不责备的记录方式错当成擦除或排名`,
          `推断题|What does the writer say about grammar charts kept by classmates?|They were useless in every situation|They sometimes led to faster progress on tests|They were unsystematic and should be abandoned|They always produced greater confidence|1|3|把部分同学在测试上更快的有限事实扩大成全面优劣判断`,
        ],
      },
      {
        title: 'The School Magazine That Stayed on Paper',
        paragraphs: [
          `For nearly thirty years the school magazine has appeared in paper, with a cover drawn by a different student each term. When the administration suggested moving it online, the editorial team did not object on grounds of cost or nostalgia. They argued that a printed copy changes how a piece of writing is read. A page cannot be scrolled past, refreshed or buried under a feed of newer posts, so it waits on a library table.`,
          `The students tested their claim in a modest way during the spring term. They printed the same issue in two forms, one posted to the school platform and one left in stacks by the entrance. Readers of the digital version tended to remember headlines but few of the longer articles. Those who picked up a paper copy were more likely to finish a page and recall a sentence or two a week later.`,
          `Part of the explanation may lie in the absence of competing signals. A screen invites a message, a notification or another tab, and reading becomes one activity among many. Paper offers no such doorway, so the reader settles into a single stretch of time. Teachers pointed out that this is not a virtue of ink itself, but of the boundaries it happens to create.`,
          `The magazine also carries a social weight that a platform page struggles to reproduce. Contributors see their names beside a drawing, a poem and a photograph chosen by someone in the year above them. Holding the finished object makes the collaboration visible in a way a scrolling list does not. Former students often write to ask for a spare copy years later, long after the online posts have been archived and forgotten.`,
          `In the end the team chose a compromise that satisfied almost no one completely. The magazine remained in print, while a plain digital archive was added for those who had left the town. The editors were careful not to call paper superior in every respect, only better at the slow reading they wanted to protect. Their decision is less a verdict on technology than a reminder that a medium quietly shapes the attention it receives.`,
        ],
        zh: [
          `近三十年来，这份校刊一直以纸质出版，每期封面由不同学生绘制。当校方提议把它搬到网上时，编辑部并没有以成本或怀旧为由反对。他们争辩说，印在纸上的一份东西，会改变一篇文章被阅读的方式。一页纸没法被滑过去、刷新掉，也没法被更新的信息流埋住。它摆在图书馆的桌上等着，结果竟成了一种安静却实在的注意力。`,
          `春季学期里，学生们用一个不大的办法检验了这个说法。同一期内容印成两种形式，一份发到学校平台，一份摞在入口处。读数字版的人往往只记得标题，长文章记住的很少。而拿起纸质版的人，更可能把一页读完，一周后还能想起一两句。样本很小，也说不上科学，但差别稳定得足以让编辑部停下来想一想。`,
          `一部分解释，也许在于没有互相争抢的信号。屏幕会招来一条消息、一个提醒或另一个标签页，阅读于是变成许多相互争抢的活动之一。纸不提供这样的出口，读者便安顿进一整段不被打断的时间里。注意到这场实验的老师指出，这并不是油墨本身的美德，而是它恰好划出的边界。一个干扰更少、设计得当的数字版，原则上也能做到类似的事，只是当时还没有人做出来。`,
          `这份刊物还带着一种平台页面难以复制的分量。投稿者会看到自己的名字，挨着一幅画、一首诗，以及高年级某人挑的一张照片。把成品拿在手里，合作便以滚动列表做不到的方式变得可见。毕业多年的学生常写信来讨一本多余的，那时网上的帖子早被归档、被忘了。对一所小小的学校来说，这种实体上的延续，正是一份共同记忆被留住的方式之一。`,
          `最后，编辑部选了一个几乎没让任何人完全满意的折中。刊物继续印，同时加了一个朴素的数字档案，给那些已经离开这座小城的人。编辑们很小心，没有说纸在各方面都更好，只说它更适合他们想护住的那种慢读。这个决定与其说是对技术下的判决，不如说是一个提醒：媒介会悄悄塑造它得到的注意力。选择怎样出版，似乎也就是选择怎样被阅读。`,
        ],
        q: [
          `细节题|Why did the editorial team object to moving the magazine online?|Because printing was far cheaper than any website|Because the administration forbade all digital files|Because a printed page receives a different kind of attention|Because no student knew how to use a computer|2|1|把纸质阅读方式之争错记成成本或禁令问题`,
          `细节题|What did readers of the digital version tend to remember?|Mainly headlines rather than longer pieces|Nearly every sentence of the longer articles|Only the cover drawing|The names of all the contributors|0|2|把只记标题的有限记忆夸大成记住全文`,
          `推断题|What do teachers suggest about the virtue of paper?|Ink itself has a unique moral quality|Paper creates boundaries that limit competing interruptions|Digital editions can never support slow reading|Students dislike every kind of screen|1|3|把边界带来的效果偷换成油墨本身的固有优点`,
          `细节题|Why do former students write to ask for a spare copy?|To complain about the cover design|To request a refund of their fees|To submit a new poem for the next issue|To replace posts that have been archived and forgotten|3|4|把索取实体刊物用于留存记忆错当成投稿或投诉`,
          `主旨题|What does the final paragraph suggest about the compromise?|It proves that print is superior in every respect|It protects a particular kind of slow reading rather than condemning technology|It abandons print entirely within a year|It settles the debate once and for all|1|5|把有限目标的折中方案夸大成全面结论或终局定论`,
        ],
        lq: [
          `细节题|Who draws the magazine cover each term?|A different student|The school administration|A hired professional artist|The former students' association|0|1|把每期换学生绘制错记成固定机构或外聘`,
          `细节题|Where did the team leave the printed copies during the spring test?|On every classroom desk|Inside the digital archive|In stacks by the entrance|In the town library only|2|2|把入口处堆放的位置错置成课桌或档案馆`,
          `推断题|What does a screen invite according to Paragraph 3?|A single uninterrupted stretch of time|A slower and deeper reading|The absence of any competing signal|Messages, notifications or another tab|3|3|把屏幕带来的多重干扰颠倒成单一专注`,
          `推断题|What did the compromise add for people who had left the town?|Extra printed copies by post|A plain digital archive|A new cover competition|A weekly online debate|1|5|把面向离校者的数字档案错记成加印或竞赛`,
        ],
      },
    ],
    translation: {
      chinese: `街角那家旧书店已经开了二十多年，木架上的书按到货先后摆放，并不按类别分区。老板说，找书慢一点，客人反而常遇见本来不会翻开的那一本。每逢周末，店里腾出靠窗一角，办一场不需报名的朗读会。来的人有退休教师、放学的孩子，也有进来避雨的邻居。一段短文读完，大家随意聊几句，话题常从书里滑到各自的近处生活。有人问为什么不搬到线上，老板指了指窗外：雨停了，人自然散了，可总有人下周还来。这种不记名、不打卡的相聚，让小书店慢慢成了街区的客厅。`,
      hints: ['second-hand bookshop', 'in the order they arrived', 'come across a volume', 'a reading aloud session', 'drift into their everyday lives'],
      reference: `The second-hand bookshop on the corner has been open for more than twenty years. On the wooden shelves behind the counter, books stand in the order they arrived rather than by category. The owner says that when the search is a little slower, customers often come across a volume they would never otherwise have opened. Every weekend the shop clears a corner by the window for a reading aloud session that requires no registration. Those who come include retired teachers, children just out of school, and neighbours who simply stepped in to escape the rain. When a short passage ends, people chat casually, and the talk often drifts from the book into their everyday lives. Someone once asked why the event was not moved online. The owner pointed out of the window: the rain stops, people naturally drift away, yet somebody always returns the following week.`,
      scoringPoints: [
        ['按到货先后而非类别摆书', 'books stand in the order they arrived rather than by category'],
        ['找书慢反而遇见意外之书', 'a slower search leads to a volume never otherwise opened'],
        ['靠窗办不需报名的朗读会', 'hold a reading session by the window with no registration'],
        ['话题从书滑到近处生活', 'the talk drifts from the book into their everyday lives'],
        ['雨停人散却总有人再来', 'the rain stops, people drift away, yet somebody returns'],
        ['小书店成了街区的客厅', 'a small bookshop slowly becomes the neighbourhood sitting room'],
      ],
      highlights: ['has been open for more than ...', 'rather than by category', 'would never otherwise have opened', 'Those who come include ...', 'drift from ... into ...', 'somebody always returns the following week'],
    },
    writing: {
      topic: 'Why School Libraries Still Matter',
      prompt: 'Directions: For this part, you are allowed 30 minutes to write an essay on why school libraries still matter. You should write at least 150 words but no more than 190 words.',
      requirements: ['150–190 words', '30 minutes', '3 paragraphs: thesis → librarians and serendipity → trust and lasting habit'],
      outlineHints: [
        '开头：图书馆被低估，它提供难得的「被允许空闲」，是私人好奇的起点。',
        '中间：馆员的摆放与顺手推荐是课表外的引导；偶遇比速度更珍贵。',
        '结尾：不替代课堂，但把浏览时间信任地交给学生，影响长过一次作业。',
      ],
      modelEssay: [
        `A school library is easy to underestimate, since it looks like a room that simply holds books. It is one of the few places where a student may sit without buying anything or being tested. That permission to be unoccupied is rare, and an afternoon with no purpose can begin a private curiosity.`,
        `The best librarians arrange more than shelves. They put a returned novel face-out near the door and recommend a poet to someone who came for something else. Such acts appear in no timetable, yet they shape what a student reads for years. A search engine finds answers faster, but rarely offers the unexpected book beside the one you sought. Serendipity, not speed, may be the library's quietest gift.`,
        `None of this means a library can replace a classroom or a good teacher. A school that treats its library as spare space has misunderstood what it owns. Protecting time to browse and follow a stray reference trusts students with their own attention. Long after a particular title is forgotten, the memory of being allowed to wander may remain, and that is no small part of an education.`,
      ],
      structure: [
        '第一段：图书馆不只是藏书房间，它提供无需消费、考试或解释的「被允许空闲」，滋养私人好奇。',
        '第二段：馆员用摆放与顺手推荐做课表外的引导；搜索引擎更快，却难给出意外之书，偶遇才是礼物。',
        '第三段：图书馆不替代课堂，但把浏览与重读的时间交给学生，是信任其注意力，影响超过某一次作业。',
      ],
      expressions: ['easy to underestimate', 'permission to be unoccupied', 'a genuinely private curiosity', 'do not appear in any timetable', 'Serendipity, not speed', 'trusting students with their own attention', 'no small part of an education'],
      translation: [
        `学校图书馆容易被低估，因为它看上去不过是一间放着书的屋子。可只要仔细观察过就会明白，它做的远不止这些。它是校园里少有的地方：学生可以坐在那里，不必买任何东西，不必被测验，也不必解释自己为什么在那儿。这种「被允许空闲」的许可，比听上去更稀有。对一个正长成自己兴趣的年轻人来说，一个没有指定任务的下午，可能正是一段真正私人的好奇心的起点。`,
        `馆员懂得这一点，所以最出色的馆员布置的不只是书架。他们把刚归还的小说封面朝外摆在门边，把一叠地图放在历史论文旁边，还会顺手给本来来找别的东西的人推荐一位诗人。这些细小的引导不会写进任何课程表，却常常影响一个学生此后多年的阅读。搜索引擎能更快地找到答案，却很少把一本意外的书，放到你本来要找的那本旁边。图书馆最安静的礼物，也许是偶遇，而不是速度。`,
        `这并不是说图书馆能取代课堂、实验室或一位好老师。它只是意味着，把图书馆当成闲置空间的学校，误解了自己手里拥有什么。保护浏览、重读、顺着一条偶然注释追下去的时间，其实是把注意力交还给学生、并信任他们。在那里养成的习惯，比任何一次作业都更长久。某本书的书名早被忘记之后，被允许随意游走的记忆可能还留着，而这恰恰是教育里不算小的一部分。`,
      ],
    },
  },

  // =====================================================================
  // tem8：文学批评、思想史、全球化与文化、翻译。评论思辨、含蓄立场、
  // 抽象概念，题目侧重作者语气与修辞意图。
  // =====================================================================
  tem8: {
    theme: '译句的余生与世界文学的版图',
    date: '2026-11-06',
    articles: [
      {
        title: 'The Afterlife of a Translated Sentence',
        paragraphs: [
          `A translated sentence leads a double life, which is easiest to grasp when the translation is old. The words belong to the language into which they have been carried, yet their rhythm hints at a grammar no longer visible. Readers who do not know the original often sense this foreignness without being able to name it. Some call it stiffness, a defect to be smoothed away; others suspect the slight resistance is where much of the meaning quietly settled.`,
          `The dispute is really about what a translation is expected to do. If its duty is to deliver content, every trace of the source is an obstruction and the ideal version reads as though written that morning in the target language. If its duty is to register an encounter between languages, then perfect ease may be a kind of dishonesty. Neither position is comfortable, and most practising translators live somewhere between the two.`,
          `History complicates the choice further, because what counts as natural changes with the decades. A version that once felt boldly literal can, a century later, sound arch and strange, while a fluent rendering of the same period may now seem flat. The translator cannot control this drift, any more than a writer can control the future reputation of a metaphor. What was an act of hospitality in one generation becomes, without anyone intending it, an exercise in nostalgia in the next.`,
          `Critics sometimes speak of fidelity as though it were a measurable quantity. The metaphor is misleading, since languages do not divide the world into identical units. A word heavy with rural association in one tongue may have no counterpart that is not faintly comic in another. Choosing the lesser distortion is therefore an act of judgement rather than calculation. The best translators describe their work as compromise, a loyalty to an effect rather than to words.`,
          `There is also a politics of smoothness, though it is rarely stated aloud. Editions prepared for a broad market are often encouraged to dissolve unfamiliar names, idioms and structures into something immediately digestible. The result is hospitable, and quietly reassuring, because it confirms the reader in the feeling that everywhere is more or less like home. A translation that leaves a few edges unplaned asks the reader to admit that a different way of arranging experience exists.`,
          `Perhaps the most honest account of translation is a modest one. It is not a mirror, a window or a betrayal, but a second composition made under constraint, answerable to a work it can never fully reproduce. To read it well is to hold two absences at once: the original that is not there, and the reader the translator imagined but cannot know. That unresolved condition is not a failure to be repaired, but the form the work happens to take.`,
        ],
        zh: [
          `一句被翻译过来的话过着双重生活，而当译本年代久远时，这一点最容易体会。纸上的词属于它被带进去的那门语言，可它的节奏总在暗示一套已经看不见的语法。不懂原文的读者，常常能感到这丝淡淡异质，却说不出它是什么。有人称之为生硬，把它当成该被抹平的毛病。也有人隐约觉得，那点不大的阻力，恰恰是相当一部分意义悄悄落定的地方。`,
          `这场争执真正关乎的，是翻译被期待去做什么。如果它的职责是传递内容，那么来源语的每一丝痕迹都是障碍，理想的译文读起来应像当天早晨刚用目标语写成。如果它的职责是记下两种语言之间的一次相遇，那么彻底的顺滑反而可能是一种不诚实。两种立场都不太舒服：前一种有抹去异域作品之险，后一种又有把阅读变成语言学课之险。多数实际做翻译的人，住在两者之间的某处。`,
          `历史让选择更复杂，因为什么算自然，会随年代而变。一个当年显得大胆直译的版本，一百年后可能听来古雅而刻意古怪；同一时期流畅的译笔，如今却可能显得平淡。译者控制不了这种漂移，正如作家控制不了一个比喻日后的名声。一代人殷勤待客的举动，无须谁有意安排，到下一代就成了怀旧的练习。句子在它的制造者停手之后，仍在继续移动。`,
          `批评者有时谈起忠实，仿佛它是一个可测量的量，是两段文本之间原则上能缩到零的距离。这个比喻让人安心，却有误导性，因为语言并不把世界切成一模一样的单位。一个在某门语言里带着浓重乡土联想的词，换到另一门语言，可能找不到不略带滑稽的对应。于是选择较小的失真，靠的是判断而非计算，而最出色的译者往往用「折中」的字眼描述自己的工作。可以说，忠实是对一种效果的忠诚，而不是对一份词汇清单的忠诚。`,
          `顺滑之中还藏着一种政治，只是很少被明说。面向大市场准备的版本，常被鼓励把陌生的名字、习语和结构，化进立刻就能消化的东西里。结果是好客的，也悄悄令人安心，因为它让读者更确信：别处大体都和家里差不多。而保留几处未刨平棱角的译文，做的正相反：它请读者承认，安排经验的方式还可以是另一种。这个请求是否被欢迎，取决于时代，倒不太取决于文本本身。`,
          `也许对翻译最诚实的说法，是谦逊的说法。它不是镜子，不是窗，也不是背叛，而是在约束之下写成的第二篇作品，要对一件它永远无法完全复现的作品负责。要把它读好，就得同时托住两种缺席：不在场的原文，以及译者想象过、却无从认识的读者。句子在两者之间继续它双重的生活，既不完全异域，也不完全安居。这种未获解决的状态，不是有待修补的失败，而正是这件作品恰好采取的形式。`,
        ],
        q: [
          `态度题|How does the author regard the "slight resistance" of an old translation?|As a clear defect that editors should remove|As a sign that the translator lacked skill|As a place where much of the meaning may reside|As proof that the original was badly written|2|1|把含蓄肯定的陌生感误判成应当抹平的缺陷`,
          `推断题|What does the author imply about the ideal of perfect fluency?|It may amount to a kind of dishonesty about the encounter between languages|It is the only legitimate goal of translation|It always preserves the foreign work intact|It is required by every modern publisher|0|2|把对流畅的复杂保留简化成唯一合法目标`,
          `修辞题|Why does the author say a translation can become "an exercise in nostalgia"?|Because translators deliberately imitate old styles|Because readers prefer only ancient texts|Because publishers reprint old covers unchanged|Because naturalness shifts over time, so once-bold choices later sound arch|3|3|把时间造成的语感漂移误读成译者有意的仿古`,
          `细节题|Why does the author call the idea of measurable fidelity misleading?|Translators rarely consult dictionaries|Languages do not divide the world into identical units|No two readers ever agree on a plot|Original manuscripts are usually lost|1|4|把语言单位不可对应的论点错置成材料散佚问题`,
          `态度题|What is the author's tone toward market-driven smooth editions?|Wholehearted approval of their hospitality|Quietly critical, noting they reassure readers that everywhere resembles home|Open hostility toward all popular books|Complete indifference to editorial choices|1|5|把含蓄批评的语气误读成全然赞同或激烈敌视`,
        ],
        lq: [
          `推断题|Whom does the author say can often sense a translation's foreignness?|Readers who do not know the original|Only professional linguists|The original author alone|Publishers checking sales figures|0|1|把普通读者的隐约感知错置成只有专家能察觉`,
          `细节题|What can a translator not control, according to Paragraph 3?|The price of the printed edition|The length of the source manuscript|The choice of the target language|The future reputation of a metaphor or the drift of naturalness|3|3|把不可控的历史语感漂移错记成定价或篇幅`,
          `推断题|What do practising translators tend to emphasise in describing their work?|Exact mathematical equivalence|Complete freedom from the source|Compromise and loyalty to an effect rather than to words|The speed of production|2|4|把折中与效果忠诚的立场偷换成精确对等或脱离原文`,
          `修辞题|What is the effect of describing translation as "not a mirror, a window or a betrayal"?|It insists a translation must reproduce the original exactly|It rejects familiar metaphors to frame translation as a constrained second composition|It compares reading to a financial transaction|It argues that all translations are deliberate deceptions|1|6|把否定常见比喻以重下定义的修辞意图误读成要求逐字复制`,
        ],
      },
      {
        title: 'The Idea of a World Literature',
        paragraphs: [
          `The phrase world literature is uttered with such ease that its strangeness is easy to miss. It suggests a single shelf on which every tradition might be arranged, a common space where a novel from one continent can be compared with a poem from another. Yet the shelf was built at a particular moment, by particular institutions, with particular ideas about what counts as worth keeping. The category is a map, and like all maps it has edges.`,
          `Those edges were drawn by translation, criticism, prizes and syllabi long before any geographer drew them. A text becomes world literature not through intrinsic quality alone, but because it circulates beyond its place of origin, usually in a language of wide reach. This circulation is uneven, since some routes are well paved and others barely marked. A writer in a small language may wait decades for a translator, while a neighbour in a dominant language is reviewed abroad within a season.`,
          `Defenders of the category answer that circulation, however unequal, still enlarges the conversation. A reader who meets a distant work is invited to revise what is possible in a sentence, and the invitation is genuine even when the door is narrow. There is a real gain in the comparison that a shared shelf permits. The question is whether the gain is being distributed, or merely collected at a few well-lit centres.`,
          `A further complication lies in the expectation of representativeness. Works that travel are often asked to stand for an entire culture, to explain a region to readers who will meet no other book from it. The burden quietly flattens the work itself, turning a quirky, private novel into a dutiful ambassador. Authors who resist this role are accused of being insufficiently local, while those who accept it risk writing for an imagined foreign judge.`,
          `It would be too simple to conclude that the whole enterprise should be abandoned. The alternative is not a pure, unmediated encounter with a text, which never existed, but a more crowded set of mediations that nobody has bothered to examine. A more self-aware criticism would keep the shelf while naming who stocked it, which routes were taken, and what was left in the warehouse. Innocence, here, is a luxury of the centre.`,
          `Seen in this light, world literature is less a finished collection than an ongoing argument about attention. It asks who is read, in which language, under what description, and with how much of their oddness intact. The most valuable works may be those that refuse to sit neatly on the shelf, keeping a residue the importing language cannot settle. To read them well is to allow the map to be redrawn, and to accept that a world of letters should stay slightly unfamiliar.`,
        ],
        zh: [
          `「世界文学」这个说法被说得如此顺口，以至于它的奇怪之处很容易被漏掉。它暗示有那么一个书架，所有传统都能在上面排开；有那么一个共同空间，一个大陆的小说可以与另一个大陆的诗相比。可这个书架是在某个特定时刻、由某些特定机构、带着关于「什么算值得留下的作品」的某些特定观念搭起来的。因此，谈一个文字的世界，也就是谈使这样一个世界变得可以想象的网络。这个类别是一张地图，而像所有地图一样，它有边界。`,
          `这些边界，早在任何地理学家动手之前，就已被翻译、批评、奖项和教学大纲划好。一部文本成为世界文学，并非只因某种内在品质，而是因为它开始在生产它的地方之外流通，且通常借一门辐射很广的语言。这种流通从设计上就不均匀：有些路铺得平整，有些几乎看不出痕迹。用小型语言写作的人，可能要等上几十年，才碰巧等来一位译者；而隔壁用强势语言写作的人，一季之内就在国外被评论了。看上去，偶然穿上了才能的外衣。`,
          `为这个类别辩护的人会回应：流通无论多么不平等，毕竟把交谈拓宽了。遇见一部远方作品的读者，被请去修正「一句话里什么算可能」的尺度，即便门很窄，这份邀请也是真的。一个共同书架所容许的比较，确有一份收获；若每种文学都封在自己的地方里，这份收获就没了。问题在于，这份收获是在被分发，还是只是在少数灯火通明的中心被收集。单靠赞叹，回答不了它。`,
          `还有一层复杂，在于「代表性」的期待。得以远行的作品，常被要求替一整个文化站台，向那些不会再读到它第二本书的读者解释一个地区。这份担子并不公平，还悄悄把作品本身压平：一部古怪、私人的小说，被改造成一位尽职的使者。拒绝这个角色的作者，有时被指不够本土；接受它的作者，又可能是在为一个想象中的外国裁判写作。无论哪条路，第一页还没翻，阅读就已经歪了。`,
          `若就此断定整件事该被放弃，又太简单了。替代方案并不是与文本纯粹、无中介的相遇，那样的相遇从来不曾存在；而是一堆更拥挤、却没人费心去审视的中介。一种更有自知之明的批评，会保留这个书架，同时点明是谁上的书、走了哪几条路、又有什么留在了仓库里。这样的留意并不毁掉读一本远方书的愉快，只是不肯假装这份愉快是自己找上门来的。在这里，天真，是中心才享用得起的奢侈品。`,
          `这样看，世界文学与其说是一套已完成的收藏，不如说是一场关于注意力尚未结束的争论。它追问谁被读到、用哪门语言、顶着怎样的说明，又保留了多少自己的古怪。最有价值的作品，或许恰恰是那些不肯规规矩矩待在书架上、总留着一点输入语消化不掉的残余的东西。把它们读好，就是容许地图被稍稍重画，并接受：一个配得上这名字的文字世界，本该始终带点陌生。`,
        ],
        q: [
          `修辞题|What does the author achieve by calling the category "a map"?|To praise its completeness and perfect accuracy|To argue that geography should replace literary study|To claim that maps are more reliable than texts|To suggest it has edges and was drawn from a particular standpoint|3|1|把地图比喻暗含的局限与立场误读成对完备性的赞许`,
          `细节题|According to Paragraph 2, how does a text become world literature?|By circulating beyond its place of origin, often in a widely used language|By being written in the oldest known language|By winning a prize in its own country only|By avoiding translation altogether|0|2|把跨语际流通的机制错记成获奖或拒绝翻译`,
          `态度题|What is the author's attitude toward the defenders of circulation?|Dismissive of any possible gain|Certain that all centres share it equally|Receptive to the gain but unresolved about how it is distributed|Convinced that comparison is impossible|2|3|把承认收益又追问分配的保留立场简化成全盘否定`,
          `推断题|What does the author imply about works asked to represent a whole culture?|They become more accurate as a result|They are quietly flattened into dutiful ambassadors|They are always translated without loss|They stop being read abroad entirely|1|4|把代表制带来的扁平化错当成更准确或不再流通`,
          `修辞题|What is the function of the phrase "Innocence, here, is a luxury of the centre"?|To praise readers at the centre for their purity|To argue that criticism should stop examining institutions|To describe the price of imported books|To ironically note that unawareness of mediation is itself a privileged position|3|5|把反讽式的立场揭示误读成对中心读者的赞美`,
        ],
        lq: [
          `细节题|What drew the edges of world literature before any geographer did?|National borders drawn at peace conferences|The physical distance between continents|The personal taste of a single novelist|Translation, criticism, prizes and syllabi|3|2|把制度性流通渠道错置成地理边界或个人趣味`,
          `推断题|Why may a writer in a small language wait decades?|Because small languages lack any grammar|Because such writers refuse to publish|Because circulation depends on the accident of a translator|Because prizes are banned in their country|2|2|把流通渠道不均的等待错归因于语言本身或禁令`,
          `推断题|What risk do authors face if they accept the ambassador role?|They may write for an imagined foreign judge|They will never be translated again|They lose the ability to use their own language|They are guaranteed a wider readership at home|0|4|把迎合外部评判的风险错置成失去母语或必然畅销`,
          `态度题|What does the author suggest about abandoning the whole enterprise?|It is the only honest option available|The alternative is a more crowded, unexamined set of mediations|It would immediately restore pure reading|It has already happened in most universities|1|5|把对放弃论的反驳误读成对纯真阅读的恢复`,
        ],
      },
    ],
    translation: {
      chinese: `一座港口城市的档案馆近年启动了一项口述计划，记录街坊对方言的记忆。城市因码头而兴，几代移民把乡音带进同一条巷子，口音在日常买卖中慢慢磨平。研究者发现，人们记得最牢的往往不是字词，而是叫卖的调子、节庆祝词，以及长辈训话时冒出的一句土话。这些声音依附于具体场景，离开厨房或渡口便难以复述。整理者不急于给词条下定论，先记下说话的人、地点和天气。有人嫌这工作琐碎，难称学问。主持者却回答：方言不是等待封存的清单，而是仍被讲述的关系；记录得越细，后来的人越能听出，哪些被时间带走，哪些被悄悄留下。`,
      hints: ['an oral project', 'the local dialect', 'worn smooth by everyday trade', 'cling to particular settings', 'not a list waiting to be sealed'],
      reference: `The archive of a port city recently began an oral project devoted to old residents' memories of the local dialect. The city grew around its docks, and successive waves of migrants carried their home accents into the same narrow lanes, where the rough edges were worn smooth by everyday trade. Researchers found that what people recall most vividly is rarely the words themselves, but the cadence of street cries, festival blessings, and a sudden phrase that an elder let slip while scolding a child. Such sounds cling to particular settings; once removed from a kitchen or a ferry, they can hardly be reproduced. Rather than fix every entry, the compilers first set down who was speaking, where, and the weather. Some object that the work is too trivial for scholarship. The director answers that a dialect is not a list waiting to be sealed, but a relationship still being narrated; the finer the record, the more clearly later listeners hear what time carried away and what people quietly kept.`,
      scoringPoints: [
        ['记录老街坊对方言的记忆', 'record old residents memories of the local dialect'],
        ['几代移民把乡音带进同一条巷子', 'successive waves of migrants carried home accents into the same lanes'],
        ['口音在日常买卖中被慢慢磨平', 'accents were gradually worn smooth by everyday trade'],
        ['记得最牢的是叫卖调子与祝词', 'what is recalled most vividly is the cadence of street cries and blessings'],
        ['先记下说话人、地点与天气', 'first set down who was speaking, where, and the weather'],
        ['方言是仍被讲述的关系而非封存清单', 'a dialect is a relationship still being narrated, not a sealed list'],
      ],
      highlights: ['devoted to ...', 'what people recall most vividly is rarely ... but ...', 'Such sounds cling to ...', 'Rather than rush to ...', 'not a list waiting to be sealed, but a relationship still being narrated', 'the finer the record, the more clearly ...'],
    },
    writing: {
      topic: 'On the Uses of Rereading',
      prompt: 'Directions: For this part, you are allowed 30 minutes to write an essay on the uses of rereading. You should write at least 180 words but no more than 220 words.',
      requirements: ['180–220 words', '30 minutes', '3 paragraphs: thesis → criticism and revision → the ethics of returning'],
      outlineHints: [
        '开头：重读被低估；书未变而读者已变，同一作品在新光下成了不同对象。',
        '中间：批评者须定论却常改观；以「重新接续的对话」取代定本幻想。',
        '结尾：重读是温和伦理，抵抗求新市场，记录不断变化又不断回返的自我。',
      ],
      modelEssay: [
        `To reread a book is often treated as a lesser act than to read a new one, as though a second encounter repeats the first. That assumption flatters a culture of novelty, and is mistaken. A book does not stay still between readings, because the reader does not either. The sentences remain identical, yet the reader has acquired disappointments and a different sense of what is at stake. What returns is the same work under a newer light, a quietly different object.`,
        `Critics are expected to deliver a settled judgement on a first encounter. Yet the most durable criticism often admits a change of mind. A passage once merely decorative can later become the hinge on which the whole argument turns. Such revisions are not failures of attention but evidence that attention has a history. To acknowledge this replaces the fantasy of a definitive reading with a conversation resumed.`,
        `There is, finally, a modest ethics in rereading. It declines the conviction that a work can be consumed and set aside, granting an object the dignity of outlasting our first opinion. In a market organised around the new, returning is a small act of refusal. A shelf of reread books is not a record of repetition; it is a record of a self that kept changing and kept coming back.`,
      ],
      structure: [
        '第一段：重读被误认为低于初读；书未变而读者已变，同一作品在新光下已是不同对象。',
        '第二段：批评者常须一次定论，但最耐久的批评承认改观；用「重新接续的对话」取代定本幻想。',
        '第三段：重读是一种温和的伦理，拒绝「可消费可搁置」，以回返抵抗求新市场，记录不断变化的自我。',
      ],
      expressions: ['a lesser act than', 'flattering to a culture that prizes novelty', 'the same work under a newer light', 'deliver a settled judgement', 'the hinge on which the whole argument turns', 'attention has a history', 'a conversation resumed', 'grants an object the dignity of outlasting', 'a small act of refusal'],
      translation: [
        `重读一本书，常被视为比读一本新书低一等的举动，仿佛第二次相遇只能重复初读早已定下的东西。这种假定恭维了一个崇尚新奇的文化，却也弄错了。两次阅读之间，书并没有静止，因为读者也没有静止。句子一字未改，可迎向它们的人已经添了失望、争论，以及对什么才算要紧的另一种分寸。于是回来的，不再是同一部作品，而是同一部作品落在一道更新的光里，成了一件悄然不同的东西。`,
        `批评者有职业上的理由抗拒这一点，因为人们期待他们在初次相遇时就给出定论。然而最经得起时间的批评，往往肯承认自己改了主意。一段当年只觉得是装饰的文字，多年后会显出它其实是整个论证借以转动的轴；一个曾被当作配角的人物，可能变成再也忘不掉的那一个。这类修正不是注意力失职，反倒证明注意力也有自己的历史。书一直在等，读者终于配得上其中的某一部分了。肯承认这一点，就等于用「一场重新接续的对话」，换掉关于定本的幻想。`,
        `最后，重读里还藏着一点温和的伦理。它不肯接受「一部作品可以被消费、被概括、被搁到一边」的轻巧确信，而把「比我们最初对它的看法活得更久」这种尊严还给对象。在一个围绕新货组织起来的市场里，选择回返几乎是一桩小小的拒绝。它暗示价值也许不在于翻过多少书名，而在于耐心地留在少数几本旁边。一架重读过的书，不是重复的流水账，而是一个不断改变、又不断回来的自我的记录。`,
      ],
    },
  },
};
