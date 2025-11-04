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
  resetCodeExpires: Date
});
const UserModel = mongoose.model('users', UserSchema);

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

const PORT = process.env.PORT || 3001;
app.listen(PORT, '0.0.0.0', () => console.log(`Server is running on port ${PORT}`));