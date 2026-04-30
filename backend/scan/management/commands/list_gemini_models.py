from django.core.management.base import BaseCommand
from django.conf import settings


class Command(BaseCommand):
    help = "List available Gemini models that support generateContent"

    def handle(self, *args, **options):
        try:
            import google.generativeai as genai  # type: ignore
        except Exception:
            self.stderr.write("google-generativeai is not installed.")
            return

        api_key = getattr(settings, "GEMINI_API_KEY", "") or ""
        if not api_key:
            self.stderr.write("GEMINI_API_KEY is not set.")
            return

        genai.configure(api_key=api_key)

        try:
            models = genai.list_models()
        except Exception as exc:
            self.stderr.write(f"Failed to list models: {exc}")
            return

        out = []
        for model in models or []:
            name = getattr(model, "name", None)
            methods = getattr(model, "supported_generation_methods", None) or []
            if not name:
                continue
            if "generateContent" in list(methods):
                out.append(str(name))

        if not out:
            self.stdout.write("No models with generateContent found.")
            return

        self.stdout.write("\n".join(sorted(out)))

