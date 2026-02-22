package com.eksystems.homes.common.interceptor.config;

import com.eksystems.homes.common.interceptor.LoginInterceptor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(new LoginInterceptor())
                .addPathPatterns("/**")
                .excludePathPatterns(
                        "/login", "/login/**",
                        "/loginProcess",         // ✅ 이거 반드시!
                        "/logout",
                        "/error", "/error/**",
                        "/css/**", "/js/**", "/assets/**",
                        "/favicon.ico"
                );
    }
}
