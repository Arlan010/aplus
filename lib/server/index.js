require('dotenv').config();

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bodyParser = require('body-parser');
const bcrypt = require('bcryptjs');
const nodemailer = require('nodemailer');

const app = express();
app.use(cors());
app.use(bodyParser.json());

mongoose.connect(process.env.MONGO_URL)
  .then(() => console.log('MongoDB connected'))
  .catch(error => console.log(error));

const UserSchema = new mongoose.Schema({
  full_name: String,
  email: { type: String, unique: true },
  password: String,
  resetCode: String,
  resetCodeExpires: Date,
  gradingSystem: { type: String, enum: ["5", "100"], default: "100" }
});
const UserModel = mongoose.model('users', UserSchema);

const GradeSchema = new mongoose.Schema({
  email: { type: String, required: true },
  subject: { type: String, required: true },
  grades: [
    {
      date: { type: String, required: true },
      grade: { type: Number, required: true },
      type: { type: String, default: "regular" },
    },
  ],
});

GradeSchema.index({ email: 1 });

const GradeModel = mongoose.model("grades", GradeSchema);

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

async function sendEmail(to, subject, text) {
  try {
    await transporter.sendMail({
      from: `"Aplus App" <${process.env.EMAIL_USER}>`,
      to,
      subject,
      text
    });
    console.log('Email сәтті жіберілді!');
  } catch (error) {
    console.error('Email жіберу қатесі:', error);
  }
}

function validatePassword(password) {
  const minLength = 8;
  const hasUpperCase = /[A-Z]/.test(password);
  const hasLowerCase = /[a-z]/.test(password);
  const hasNumber = /[0-9]/.test(password);
  const hasSpecial = /[!@#$%^&*(),.?":{}|<>]/.test(password);

  if (password.length < minLength) return 'Құпиясөз кемінде 8 таңбадан тұруы керек';
  if (!hasUpperCase) return 'Құпиясөзде кемінде бір бас әріп болуы керек';
  if (!hasLowerCase) return 'Құпиясөзде кемінде бір кіші әріп болуы керек';
  if (!hasNumber) return 'Құпиясөзде кемінде бір сан болуы керек';
  if (!hasSpecial) return 'Құпиясөзде кемінде бір арнайы таңба болуы керек';
  return null;
}

app.post('/register', async (req, res) => {
  try {
    const { full_name, email, password } = req.body;

    const existingUser = await UserModel.findOne({ email });
    if (existingUser) return res.status(400).json({ message: 'Бұл email тіркелген' });

    const passwordError = validatePassword(password);
    if (passwordError) return res.status(400).json({ message: passwordError });

    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = new UserModel({ full_name, email, password: hashedPassword });
    await newUser.save();

    await sendEmail(email, 'Aplus тіркелу сәтті өтті', `Сәлем, ${full_name}! Сіз Aplus жүйесіне сәтті тіркелдіңіз.`);

    res.json({ message: 'Тіркелу сәтті өтті', user: newUser });
  } catch (error) {
    res.status(500).json({ message: 'Қате: ' + error.message });
  }
});

app.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await UserModel.findOne({ email });
    if (!user) return res.status(400).json({ message: 'Мұндай email табылмады' });

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) return res.status(400).json({ message: 'Құпиясөз қате' });

    res.json({ message: 'Кіру сәтті өтті', user });
  } catch (error) {
    res.status(500).json({ message: 'Қате: ' + error.message });
  }
});

app.get('/user/:email', async (req, res) => {
  try {
    const { email } = req.params;
    const user = await UserModel.findOne({ email }).select('-password');
    if (!user) return res.status(404).json({ message: 'Пайдаланушы табылмады' });
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: 'Қате: ' + error.message });
  }
});

app.put('/user/:email', async (req, res) => {
  try {
    const { email } = req.params;
    const { full_name, newEmail } = req.body;

    const updatedUser = await UserModel.findOneAndUpdate(
      { email },
      { full_name, email: newEmail || email },
      { new: true }
    ).select('-password');

    if (!updatedUser) return res.status(404).json({ message: 'Пайдаланушы табылмады' });
    res.json({ message: 'Профиль сәтті жаңартылды', user: updatedUser });
  } catch (error) {
    res.status(500).json({ message: 'Қате: ' + error.message });
  }
});

app.put('/user/:email/password', async (req, res) => {
  try {
    const { email } = req.params;
    const { oldPassword, newPassword } = req.body;

    const user = await UserModel.findOne({ email });
    if (!user) return res.status(404).json({ message: 'Пайдаланушы табылмады' });

    const isPasswordValid = await bcrypt.compare(oldPassword, user.password);
    if (!isPasswordValid) return res.status(400).json({ message: 'Ескі құпиясөз қате' });

    const passwordError = validatePassword(newPassword);
    if (passwordError) return res.status(400).json({ message: passwordError });

    const hashedNewPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedNewPassword;
    await user.save();

    res.json({ message: 'Құпиясөз сәтті жаңартылды' });
  } catch (error) {
    res.status(500).json({ message: 'Қате: ' + error.message });
  }
});

app.get("/grades/:email", async (req, res) => {
  try {
    const { email } = req.params;
    const userGrades = await GradeModel.find({ email }).sort({ subject: 1 });

    userGrades.forEach((sub) => {
      sub.grades.sort((a, b) => {
        const dateA = new Date(a.date.split('.').reverse().join('-'));
        const dateB = new Date(b.date.split('.').reverse().join('-'));
        return dateA - dateB;
      });
    });

    res.json(userGrades);
  } catch (error) {
    res.status(500).json({ message: "Қате: " + error.message });
  }
});

app.post("/grades/add-subject", async (req, res) => {
  try {
    const { email, subject } = req.body;

    if (!email || !subject)
      return res.status(400).json({ message: "Email және пән атауы қажет" });

    const existing = await GradeModel.findOne({ email, subject });
    if (existing)
      return res.status(400).json({ message: "Бұл пән бұрын қосылған" });

    const newSubject = new GradeModel({
      email,
      subject,
      grades: [],
    });

    await newSubject.save();
    res.json({ message: "Пән сәтті қосылды", subject: newSubject });
  } catch (error) {
    res.status(500).json({ message: "Қате: " + error.message });
  }
});

app.post("/grades/add-grade", async (req, res) => {
  try {
    const { email, subject, date, grade, type } = req.body;

    const subjectDoc = await GradeModel.findOne({ email, subject });
    if (!subjectDoc)
      return res.status(404).json({ message: "Пән табылмады" });

    if (subjectDoc.grades.some((g) => g.date === date)) {
      return res.status(400).json({ message: "Бұл күнге баға бұрын енгізілген" });
    }

    subjectDoc.grades.push({ date, grade, type: type || "regular" });
    await subjectDoc.save();

    const avg =
      subjectDoc.grades.reduce((acc, g) => acc + g.grade, 0) /
      subjectDoc.grades.length;
    res.json({
      message: "Баға сәтті қосылды",
      subject: subjectDoc,
      average: avg.toFixed(2),
    });
  } catch (error) {
    res.status(500).json({ message: "Қате: " + error.message });
  }
});

app.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;
    const user = await UserModel.findOne({ email });
    if (!user) return res.status(404).json({ message: 'Мұндай email табылмады' });

    const code = Math.floor(100000 + Math.random() * 900000).toString();
    user.resetCode = code;
    user.resetCodeExpires = Date.now() + 10 * 60 * 1000;
    await user.save();

    await sendEmail(email, 'Құпиясөзді қалпына келтіру', `Сіздің растау кодыңыз: ${code}`);

    res.json({ message: 'Растау коды email арқылы жіберілді' });
  } catch (error) {
    res.status(500).json({ message: 'Қате: ' + error.message });
  }
});

app.post('/reset-password', async (req, res) => {
  try {
    const { email, code, newPassword } = req.body;
    const user = await UserModel.findOne({ email });

    if (!user || user.resetCode !== code || user.resetCodeExpires < Date.now()) {
      return res.status(400).json({ message: 'Код жарамсыз немесе уақыты өтті' });
    }

    const passwordError = validatePassword(newPassword);
    if (passwordError) return res.status(400).json({ message: passwordError });

    const hashed = await bcrypt.hash(newPassword, 10);
    user.password = hashed;
    user.resetCode = null;
    user.resetCodeExpires = null;
    await user.save();

    res.json({ message: 'Құпиясөз сәтті қалпына келтірілді' });
  } catch (error) {
    res.status(500).json({ message: 'Қате: ' + error.message });
  }
});

app.get("/grades/gpa/:email", async (req, res) => {
  try {
    const { email } = req.params;
    const subjects = await GradeModel.find({ email });

    if (!subjects || subjects.length === 0) {
      return res.json({ gpa100: 0, gpa4: 0 });
    }

    let totalGrades = 0;
    let totalCount = 0;

    subjects.forEach(sub => {
      sub.grades.forEach(g => {
        totalGrades += g.grade;
        totalCount++;
      });
    });

    if (totalCount === 0) return res.json({ gpa100: 0, gpa4: 0 });

    const gpa100 = totalGrades / totalCount;
    const gpa4 = (gpa100 / 100) * 4.0;

    res.json({
      gpa100: gpa100.toFixed(2),
      gpa4: gpa4.toFixed(2)
    });
  } catch (error) {
    res.status(500).json({ message: "Қате: " + error.message });
  }
});

app.post("/grades/required-score", async (req, res) => {
  try {
    const { email, subject, targetAverage } = req.body;

    if (!email || !subject || !targetAverage) {
      return res.status(400).json({ message: "Барлық өрістер қажет" });
    }

    const subjectDoc = await GradeModel.findOne({ email, subject });
    if (!subjectDoc || subjectDoc.grades.length === 0) {
      return res.status(404).json({ message: "Пән табылмады немесе бағалар жоқ" });
    }

    const grades = subjectDoc.grades.map(g => g.grade);
    const currentSum = grades.reduce((a, b) => a + b, 0);
    const n = grades.length;

    const requiredScore = targetAverage * (n + 1) - currentSum;

    res.json({ requiredScore: requiredScore.toFixed(2) });
  } catch (error) {
    res.status(500).json({ message: "Қате: " + error.message });
  }
});

app.delete("/grades/delete-subject", async (req, res) => {
  try {
    const { email, subject } = req.body;

    if (!email || !subject)
      return res.status(400).json({ message: "Email және пән атауы қажет" });

    const deleted = await GradeModel.findOneAndDelete({ email, subject });

    if (!deleted)
      return res.status(404).json({ message: "Пән табылмады" });

    res.json({ message: "Пән сәтті жойылды" });
  } catch (error) {
    res.status(500).json({ message: "Қате: " + error.message });
  }
});

app.put("/grades/update-grade", async (req, res) => {
  try {
    const { email, subject, oldDate, newDate, newGrade, newType } = req.body;

    if (!email || !subject || !oldDate || newGrade === undefined)
      return res.status(400).json({ message: "Барлық өрістер қажет" });

    const subjectDoc = await GradeModel.findOne({ email, subject });
    if (!subjectDoc) return res.status(404).json({ message: "Пән табылмады" });

    const gradeItem = subjectDoc.grades.find((g) => g.date === oldDate);
    if (!gradeItem) return res.status(404).json({ message: "Баға табылмады" });

    gradeItem.date = newDate || gradeItem.date;
    gradeItem.grade = newGrade;
    gradeItem.type = newType || gradeItem.type;

    await subjectDoc.save();

    const avg =
      subjectDoc.grades.reduce((acc, g) => acc + g.grade, 0) /
      subjectDoc.grades.length;
    res.json({
      message: "Баға сәтті өзгертілді",
      subject: subjectDoc,
      average: avg.toFixed(2),
    });
  } catch (error) {
    res.status(500).json({ message: "Қате: " + error.message });
  }
});


app.get("/grades/subject-average/:email/:subject", async (req, res) => {
  try {
    const { email, subject } = req.params;
    const subjectDoc = await GradeModel.findOne({ email, subject });

    if (!subjectDoc || subjectDoc.grades.length === 0)
      return res.json({ average: 0 });

    const grades = subjectDoc.grades;

    const regular = grades.filter(g => g.type === "regular");
    const sor = grades.filter(g => g.type === "СОР" || g.type === "Рубежка");
    const soch = grades.filter(g => g.type === "СОЧ" || g.type === "Сессия");

    const avg = arr => arr.length ? arr.reduce((a, b) => a + b.grade, 0) / arr.length : 0;
    const avgRegular = avg(regular);
    const avgSor = avg(sor);
    const avgSoch = avg(soch);

    const weights = {
      regular: 0.5,
      sor: 0.125,
      soch: 0.25,
    };

    const weightedSum = (avgRegular * weights.regular) +
                        (avgSor * weights.sor) +
                        (avgSoch * weights.soch);

    const totalWeight = (
      (regular.length ? weights.regular : 0) +
      (sor.length ? weights.sor : 0) +
      (soch.length ? weights.soch : 0)
    ) || 1;

    const finalGrade = weightedSum / totalWeight;

    res.json({
      average: finalGrade.toFixed(2),
      breakdown: {
        regular: avgRegular.toFixed(2),
        sor_or_rubezhka: avgSor.toFixed(2),
        soch_or_session: avgSoch.toFixed(2),
      },
    });

  } catch (error) {
    res.status(500).json({ message: "Қате: " + error.message });
  }
});

app.delete("/grades/delete-grade", async (req, res) => {
  try {
    const { email, subject, date } = req.body;

    const subjectDoc = await GradeModel.findOne({ email, subject });
    if (!subjectDoc)
      return res.status(404).json({ message: "Пән табылмады" });

    subjectDoc.grades = subjectDoc.grades.filter(g => g.date !== date);
    await subjectDoc.save();

    res.json({ message: "Баға сәтті жойылды" });
  } catch (error) {
    res.status(500).json({ message: "Қате: " + error.message });
  }
});

// 🏁 Соңғы алынған баға (последняя оценка)
app.get("/grades/last/:email", async (req, res) => {
  try {
    const { email } = req.params;
    const subjects = await GradeModel.find({ email });

    let lastGrade = null;
    let lastSubject = null;
    let lastDate = null;

    subjects.forEach(sub => {
      sub.grades.forEach(g => {
        const dateParts = g.date.split(".");
        const parsedDate = new Date(
          parseInt(dateParts[2]),
          parseInt(dateParts[1]) - 1,
          parseInt(dateParts[0])
        );

        if (!lastDate || parsedDate > lastDate) {
          lastDate = parsedDate;
          lastGrade = g.grade;
          lastSubject = sub.subject;
        }
      });
    });

    if (!lastGrade) {
      return res.json({ message: "Бағалар жоқ" });
    }

    res.json({
      subject: lastSubject,
      grade: lastGrade,
      date: `${lastDate.getDate().toString().padLeft(2, '0')}.${(lastDate.getMonth() + 1).toString().padLeft(2, '0')}.${lastDate.getFullYear()}`,
    });
  } catch (error) {
    res.status(500).json({ message: "Қате: " + error.message });
  }
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, '0.0.0.0', () => console.log(`Server is running on port ${PORT}`));