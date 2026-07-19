# smile_concept_web

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


## 🔧 Setup

### 1. Clone & Install
\`\`\`bash
git clone <repo-url>
cd smile_concept_web
flutter pub get
\`\`\`

### 2. Environment Setup
\`\`\`bash
cp .env.example .env
\`\`\`

Then edit `.env` with your backend URL:
- **Laravel Herd:** `http://localhost/api/v1`
- **php artisan serve:** `http://localhost:8000/api/v1`

### 3. Run
\`\`\`bash
flutter run
\`\`\`


### Frontend (Flutter Web)

```bash
flutter build web --release --dart-define=ENV_FILE=.env.production
```

Deploy the `build/web/` folder to:
- **Firebase Hosting:** `firebase deploy`
- **Vercel:** `vercel --prod`
- **Nginx:** Copy to `/var/www/html`

### Roboflow (Production)

**Option 1: Self-hosted (recommended for HIPAA)**
```bash
docker run -d \
  --name roboflow-inference \
  --gpus all \
  -p 9001:9001 \
  --restart unless-stopped \
  -v /var/roboflow-cache:/cache \
  roboflow/roboflow-inference-server-gpu
```

**Option 2: Roboflow Cloud API**

Change in `.env`:
```env
ROBOFLOW_API_URL=https://detect.roboflow.com
```

---

## 📊 Monitoring

### Log Files

```bash
# Laravel logs
tail -f storage/logs/laravel.log

# Queue worker logs
tail -f storage/logs/worker.log

# Roboflow container logs
docker logs -f roboflow-inference

# Nginx access logs
tail -f /var/log/nginx/access.log
```

### Health Checks

Create a health check endpoint:
```bash
curl http://localhost/api/health
curl http://localhost:9001/
```

---

## 📚 Additional Resources

- 📘 [Roboflow Inference Documentation](https://inference.roboflow.com)
- 📗 [Laravel Queue Documentation](https://laravel.com/docs/queues)
- 📕 [Flutter Documentation](https://flutter.dev/docs)
- 🎓 [Roboflow Universe (Model)](https://universe.roboflow.com/dentalxray-s3wqb)

---

## 🆘 Support

For issues or questions:

- 🐛 **Bug Reports:** [GitHub Issues](https://github.com/YOUR_ORG/smile_concept/issues)
- 💬 **Discord:** [Join our community](https://discord.gg/smileconcept)
- 📧 **Email:** dev@smileconcept.com

---

## 📝 License

Copyright © 2025 SmileConcept. All rights reserved.

---

## 🎉 Quick Start Summary

```bash
# 1. Start Roboflow inference server
docker run -d --name roboflow-inference -p 9001:9001 --restart unless-stopped roboflow/roboflow-inference-server-cpu

# 2. Start Laravel backend
cd Smile_Concept_API && php artisan serve

# 3. Start queue worker (new terminal)
php artisan queue:listen --tries=3

# 4. Start Flutter frontend (new terminal)
cd smile_concept_web && flutter run -d chrome

# ✅ Ready! Upload an X-ray and watch the magic happen 🦷✨
```

---

**Made with ❤️ by the SmileConcept Team**