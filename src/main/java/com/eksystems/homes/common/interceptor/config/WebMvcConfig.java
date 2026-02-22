package com.eksystems.homes.common.interceptor.config;

import com.eksystems.homes.common.interceptor.LoginInterceptor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
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
                        "/img/**",          // ✅ 추가 (인터셉터 제외)
                        "/favicon.ico"
                );
    }
    // ✅ 이거 추가
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/main/**")   // URL 경로
                .addResourceLocations("classpath:/img/main/");
    }
}
