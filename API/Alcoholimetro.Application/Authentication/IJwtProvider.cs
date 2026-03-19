using Alcoholimetro.Domain.Entities;

namespace Alcoholimetro.Application.Authentication;

public interface IJwtProvider
{
    string Generate(User user); 
}