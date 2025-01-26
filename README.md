# HackerHotel 2025 OTR bunq donations

![img](./what.gif)

### Setup for development

1. `cp .env.example .env` and fill in the values (see below).

2. `docker compose up`.

### Setup for production

1. Go to [Bunq web](https://bunq.me) and select the account you want to monitor. In the url (`https://web.bunq.com/user/BUNQ_USER_ID/account/BUNQ_ACCOUNT_ID`) select `BUNQ_ACCOUNT_ID` and `BUNQ_ACCOUNT_ID`.

2. In the Bunq app if you scroll down in your profile and generate an API key as `BUNQ_API_KEY`.

3. Go to https://github.com/bunq/postman and download and add to Postman. Add your API key in the environment (production), set it in the calls, and call API context: `Create installation` and `Add the device` (change body if needed, e.g. scope IP). From installation you copy `BUNQ_INSTALLATION_TOKEN`.

4. Go to your production environment in Postman and find `private_key_client`. Convert it to base64 `base64 -i private_key.pem -o private_key_base64.txt && cat private_key_base64.txt`. Copy the output as `BUNQ_PRIVATE_KEY`.

5. To deploy to fly.io, follow the instructions in the [fly.io documentation](https://fly.io/docs/getting-started/installing-flyctl/).

6. Do `fly launch`.

7. And set the above environment variables: `fly secrets set BUNQ_USER_ID=xxx BUNQ_ACCOUNT_ID=xxx BUNQ_API_KEY=xxx BUNQ_INSTALLATION_TOKEN=xxx BUNQ_PRIVATE_KEY=xxx`

8. Now you can deploy with `fly deploy`.
